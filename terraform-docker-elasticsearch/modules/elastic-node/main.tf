locals {
  # seed 노드 이름 = cluster.initial_master_nodes 에 등록될 값
  seed_node_name = "node-master-${replace(var.seed_ip, ".", "-")}"

  # elasticsearch.yml 렌더링
  elasticsearch_yml_content = templatefile("${path.module}/elasticsearch.yml", {
    cluster_name         = var.cluster_name
    node_name            = var.node_name
    role                 = var.role
    server_ip            = var.server_ip
    all_master_ips       = var.all_master_ips
    # seed 노드만 자기 자신을 initial_master_nodes 에 등록
    initial_master_node  = var.is_seed_master_node ? var.node_name : local.seed_node_name
  })

  # setup.sh 렌더링 (cloud-init runcmd 대체)
  setup_sh_content = templatefile("${path.module}/setup.sh", {
    es_version = var.es_version
    java_opts  = var.java_opts
    memory_mb  = var.memory_mb
  })

  # Dockerfile 렌더링
  dockerfile_content = templatefile("${path.module}/Dockerfile", {
    es_version = var.es_version
  })
}

# SSH 접속 공통 설정 (password 인증)
locals {
  ssh_connection = {
    type     = "ssh"
    host     = var.server_ip
    port     = var.ssh_port
    user     = var.ssh_user
    password = var.ssh_password
    timeout  = "5m"
  }
}

# ──────────────────────────────────────────────────────────────────────
# STEP 1: 설정 파일 업로드
# 원래 cloud-init write_files 단계를 file provisioner 가 대체
# ──────────────────────────────────────────────────────────────────────
resource "null_resource" "upload_configs" {
  # 설정 내용이 바뀔 때마다 재실행
  triggers = {
    elasticsearch_yml = local.elasticsearch_yml_content
    setup_sh          = local.setup_sh_content
    dockerfile        = local.dockerfile_content
  }

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    password = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  # 원격 서버에 디렉토리 먼저 생성
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /services/elasticsearch/config",
      "sudo mkdir -p /services/metricbeat/config",
      "sudo chown -R $USER:$USER /services",
    ]
  }

  # elasticsearch.yml 업로드
  # 원래: cloud-init write_files /services/elasticsearch/config/elasticsearch.yml
  provisioner "file" {
    content     = local.elasticsearch_yml_content
    destination = "/services/elasticsearch/config/elasticsearch.yml"
  }

  # Dockerfile 업로드
  # 원래: cloud-init write_files /services/elasticsearch/Dockerfile
  provisioner "file" {
    content     = local.dockerfile_content
    destination = "/services/elasticsearch/Dockerfile"
  }

  # setup.sh 업로드 (cloud-init runcmd 전체를 하나의 스크립트로)
  provisioner "file" {
    content     = local.setup_sh_content
    destination = "/tmp/setup.sh"
  }
}

# ──────────────────────────────────────────────────────────────────────
# STEP 2: setup.sh 실행
# 원래 cloud-init runcmd (kernel tuning → docker 설치 → ES 실행) 대체
# ──────────────────────────────────────────────────────────────────────
resource "null_resource" "run_setup" {
  triggers = {
    setup_sh = local.setup_sh_content
  }

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    password = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "sudo /tmp/setup.sh",
    ]
  }

  depends_on = [null_resource.upload_configs]
}

# ──────────────────────────────────────────────────────────────────────
# STEP 3: Metricbeat 실행 (선택)
# 원래 cloud-init runcmd "run metricbeat" 단계 대체
# ──────────────────────────────────────────────────────────────────────
resource "null_resource" "run_metricbeat" {
  count = (var.metricbeat_image != "" && var.monitoring_elasticsearch_host != "") ? 1 : 0

  triggers = {
    metricbeat_image = var.metricbeat_image
    config           = templatefile("${path.module}/metricbeat.yml", {
      monitoring_elasticsearch_host = var.monitoring_elasticsearch_host
    })
  }

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    password = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  # metricbeat.yml 업로드
  # 원래: cloud-init write_files /services/metricbeat/config/metricbeat.yml
  provisioner "file" {
    content = templatefile("${path.module}/metricbeat.yml", {
      monitoring_elasticsearch_host = var.monitoring_elasticsearch_host
    })
    destination = "/tmp/metricbeat.yml"
  }

  # 원래: chown root:root + docker run metricbeat
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /services/metricbeat/config",
      "sudo mv /tmp/metricbeat.yml /services/metricbeat/config/metricbeat.yml",
      "sudo chown root:root /services/metricbeat/config/metricbeat.yml",
      "sudo docker rm -f metricbeat 2>/dev/null || true",
      join(" ", [
        "sudo docker run -d --name metricbeat",
        "--net host --user root --restart unless-stopped",
        "-v /var/run/docker.sock:/var/run/docker.sock:ro",
        "-v /sys/fs/cgroup/:/hostfs/sys/fs/cgroup:ro",
        "-v /proc/:/hostfs/proc/:ro",
        "-v /:/hostfs:ro",
        "-v /services/metricbeat/config/metricbeat.yml:/usr/share/metricbeat/metricbeat.yml",
        "-v /services/metricbeat/logs:/usr/share/metricbeat/logs",
        var.metricbeat_image,
      ]),
    ]
  }

  depends_on = [null_resource.run_setup]
}
