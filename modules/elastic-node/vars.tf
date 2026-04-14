variable "server_ip" {
  type        = string
  description = "대상 서버 IP 주소"
}

variable "node_name" {
  type        = string
  description = "Elasticsearch 노드 이름 (IP 기반으로 자동 생성됨)"
}

variable "role" {
  type        = string
  description = "Elasticsearch 노드 역할"
  validation {
    condition     = contains(["master", "data"], var.role)
    error_message = "role 은 master 또는 data 만 가능합니다."
  }
}

variable "cluster_name" {
  type    = string
  default = "elasticsearch"
}

variable "es_version" {
  type    = string
  default = "8.12.2"
}

variable "is_seed_master_node" {
  type    = bool
  default = false
}

variable "seed_ip" {
  type        = string
  description = "cluster.initial_master_nodes 에 등록될 seed 노드 IP"
}

variable "all_master_ips" {
  type        = list(string)
  description = "discovery.seed_hosts 에 사용할 전체 마스터 노드 IP 목록"
}

variable "java_opts" {
  type    = string
  default = "-Xms768m -Xmx768m"
}

variable "memory_mb" {
  type    = string
  default = "1536m"
  description = "docker run -m 메모리 제한"
}

# ── SSH 접속 정보 (서버별 개별 설정) ──────────────────────────────────
variable "ssh_port" {
  type        = number
  default     = 50022
  description = "SSH 포트 (기본 22. 예: 50022)"
}

variable "ssh_user" {
  type      = string
  sensitive = true
}

variable "ssh_password" {
  type      = string
  sensitive = true
  description = "SSH 비밀번호 인증. sshd_config 에 PasswordAuthentication yes 필요"
}

# ── 모니터링 설정 (Metricbeat) ──────────────────────────────────────
variable "metricbeat_image" {
  type        = string
  default     = "docker.elastic.co/beats/metricbeat:8.12.2"
  description = "Metricbeat 이미지. 비워두면 미실행 (예: docker.elastic.co/beats/metricbeat:8.12.2)"
}

variable "monitoring_elasticsearch_host" {
  type        = string
  default     = "http://localhost:9200"
  description = "메트릭을 전송할 모니터링용 ES 주소"
}
