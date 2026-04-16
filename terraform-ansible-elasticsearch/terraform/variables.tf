# Master 노드 상세 설정
variable "masters" {
  type = map(object({
    port     = number
    user     = string
    password = string
  }))
  default = {
    "server-1" = { port = 22, user = "user", password = "password" }
    "server-2" = { port = 22, user = "user", password = "password" }
    "server-3" = { port = 22, user = "user", password = "password" }
  }
}

# Data 노드 상세 설정
variable "data_nodes" {
  type = map(object({
    port     = number
    user     = string
    password = string
  }))
  default = {
    "server-4" = { port = 22, user = "user", password = "password" }
    "server-5" = { port = 22, user = "user", password = "password" }
  }
}

variable "cluster_name" {
  type        = string
  default = "phm-elasticsearch"
  description = "Elasticsearch 클러스터 이름"
}

# Kibana 노드 설정
variable "kibana" {
  type = object({
    ip       = string
    port     = number
    user     = string
    password = string
  })
  default = {
    user = "user"
    password = "password"
    ip       = "server-5"
    port     = 22
  }
}