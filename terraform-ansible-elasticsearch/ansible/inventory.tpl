[masters]
%{ for ip, info in masters ~}
${ip} ansible_port=${info.port} ansible_user=${info.user} ansible_password=${info.password} ansible_become_password=${info.password}
%{ endfor ~}

[data]
%{ for ip, info in data_nodes ~}
${ip} ansible_port=${info.port} ansible_user=${info.user} ansible_password=${info.password} ansible_become_password=${info.password}
%{ endfor ~}

[kibana]
${kibana.ip} ansible_port=${kibana.port} ansible_user=${kibana.user} ansible_password=${kibana.password} ansible_become_password=${kibana.password}

[all:vars]
ansible_become=yes
ansible_become_method=sudo

ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

cluster_name=${cluster_name}