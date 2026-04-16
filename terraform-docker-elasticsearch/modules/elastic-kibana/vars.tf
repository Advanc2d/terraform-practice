variable "server_ip" {
  type        = string
  description = "Kibana 를 실행할 서버 IP"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH 포트"
}

variable "ssh_user" {
  type      = string
  sensitive = true
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "kibana_version" {
  type        = string
  default     = "8.12.2"
  description = "Kibana 버전 (Elasticsearch 버전과 동일하게 맞춰야 함)"
}

variable "es_seed_ip" {
  type        = string
  description = "Kibana 가 바라볼 Elasticsearch seed master 노드 IP"
}
