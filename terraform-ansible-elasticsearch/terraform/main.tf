# Ansible이 읽을 수 있는 inventory 파일을 생성합니다.
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.tpl", {
    masters    = var.masters
    data_nodes = var.data_nodes
    kibana     = var.kibana
    cluster_name = var.cluster_name
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# 인벤토리가 생성된 후 Ansible을 실행합니다.
resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "cd ../ansible && ansible-playbook -i inventory.ini site.yml"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "cd ../ansible && ansible-playbook -i inventory.ini destroy.yml"
  }
}