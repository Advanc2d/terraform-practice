locals {
  kibana_yml_content = templatefile("${path.module}/kibana.yml", {
    server_ip   = var.server_ip
    es_seed_ip  = var.es_seed_ip
  })
}

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

# ── STEP 1: 디렉토리 생성 + kibana.yml 업로드 ─────────────────────────
resource "null_resource" "upload_configs" {
  triggers = {
    kibana_yml = local.kibana_yml_content
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
      "sudo mkdir -p /services/kibana/config",
      "sudo mkdir -p /services/kibana/logs",
      "sudo chown -R $USER:$USER /services/kibana",
    ]
  }

  provisioner "file" {
    content     = local.kibana_yml_content
    destination = "/services/kibana/config/kibana.yml"
  }
}

# ── STEP 2: Kibana 컨테이너 실행 ──────────────────────────────────────
resource "null_resource" "run_kibana" {
  triggers = {
    kibana_yml  = local.kibana_yml_content
    server_host = var.server_ip
    server_port = tostring(var.ssh_port)
    server_user = var.ssh_user
    server_pass = var.ssh_password
  }

  connection {
    type        = local.ssh_connection.type
    host        = local.ssh_connection.host
    port        = local.ssh_connection.port
    user        = local.ssh_connection.user
    password    = local.ssh_connection.password
    timeout     = local.ssh_connection.timeout
  }

  provisioner "remote-exec" {
    inline = [
      # 기존 컨테이너 제거 후 재시작
      "sudo docker rm -f kibana 2>/dev/null || true",
      join(" ", [
        "sudo docker run -d --name kibana",
        "--net host",
        "--restart unless-stopped",
        "-v /services/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml",
        "-v /services/kibana/logs:/usr/share/kibana/logs",
        "docker.elastic.co/kibana/kibana:${var.kibana_version}",
      ]),
      "echo 'Kibana started. Access at http://${var.server_ip}:5601'",
    ]
  }

  depends_on = [null_resource.upload_configs]
}
