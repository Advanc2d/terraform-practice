locals {
  seed_ip = var.servers.master_seed.ip

  all_master_ips = concat(
    [var.servers.master_seed.ip],
    [for s in var.servers.master_eligible : s.ip]
  )
}

# ── Master Seed 노드 (1대) ────────────────────────────────────────────
module "master_seed" {
  source = "./modules/elastic-node"

  server_ip    = var.servers.master_seed.ip
  ssh_port     = var.servers.master_seed.port
  ssh_user     = var.servers.master_seed.user
  ssh_password = var.servers.master_seed.password

  node_name    = "node-master-${replace(var.servers.master_seed.ip, ".", "-")}"
  role         = "master"
  cluster_name = var.cluster_name
  es_version   = var.es_version

  is_seed_master_node = true
  seed_ip             = local.seed_ip
  all_master_ips      = local.all_master_ips

  java_opts = "-Xms768m -Xmx768m"
  memory_mb = "1536m"

  metricbeat_image              = var.metricbeat_image
  monitoring_elasticsearch_host = var.monitoring_elasticsearch_host
}

# ── Master Eligible 노드 (2대) ────────────────────────────────────────
module "master_eligible" {
  source = "./modules/elastic-node"
  count  = length(var.servers.master_eligible)

  server_ip    = var.servers.master_eligible[count.index].ip
  ssh_port     = var.servers.master_eligible[count.index].port
  ssh_user     = var.servers.master_eligible[count.index].user
  ssh_password = var.servers.master_eligible[count.index].password

  node_name    = "node-master-${replace(var.servers.master_eligible[count.index].ip, ".", "-")}"
  role         = "master"
  cluster_name = var.cluster_name
  es_version   = var.es_version

  is_seed_master_node = false
  seed_ip             = local.seed_ip
  all_master_ips      = local.all_master_ips

  java_opts = "-Xms768m -Xmx768m"
  memory_mb = "1536m"

  metricbeat_image              = var.metricbeat_image
  monitoring_elasticsearch_host = var.monitoring_elasticsearch_host

  depends_on = [module.master_seed]
}

# ── Data 노드 (2대) ───────────────────────────────────────────────────
module "data" {
  source = "./modules/elastic-node"
  count  = length(var.servers.data)

  server_ip    = var.servers.data[count.index].ip
  ssh_port     = var.servers.data[count.index].port
  ssh_user     = var.servers.data[count.index].user
  ssh_password = var.servers.data[count.index].password

  node_name    = "node-data-${replace(var.servers.data[count.index].ip, ".", "-")}"
  role         = "data"
  cluster_name = var.cluster_name
  es_version   = var.es_version

  is_seed_master_node = false
  seed_ip             = local.seed_ip
  all_master_ips      = local.all_master_ips

  java_opts = "-Xms768m -Xmx768m"
  memory_mb = "1536m"

  metricbeat_image              = var.metricbeat_image
  monitoring_elasticsearch_host = var.monitoring_elasticsearch_host

  depends_on = [module.master_seed, module.master_eligible]
}