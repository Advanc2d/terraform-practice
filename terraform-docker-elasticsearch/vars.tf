# ── 서버별 접속 정보 (IP + user + password 각각 설정) ────────────────
variable "servers" {
  type = object({
    master_seed = object({
      ip       = string
      port     = string
      user     = string
      password = string
    })
    master_eligible = list(object({
      ip       = string
      port     = string
      user     = string
      password = string
    }))
    data = list(object({
      ip       = string
      port     = string
      user     = string
      password = string
    }))
  })

  sensitive = true   # plan/apply 출력에서 password 가 마스킹됩니다

  default = {
    master_seed = {
      ip       = "10.20.110.80"
      port     = "50022"
      user     = "dream"
      password = "src2x8HJ2TZD"
    }
    master_eligible = [
      { ip = "10.20.110.81", port = "50022", user = "dream", password = "4KwtMvAMbvK5" },
      { ip = "10.20.110.82", port = "50022", user = "dream", password = "UCxcXB07rwQB" },
    ]
    data = [
      { ip = "10.20.110.83", port = "50022", user = "dream", password = "rrK91AvLX4j8" },
      { ip = "10.20.110.84", port = "50022", user = "dream", password = "Y8gjGveWi4Pg" },
    ]
  }
}

# ── Node 설정 ────────────────────────────────────────────────────────
variable "cluster_name" {
  type        = string
  default = "phm-elasticsearch"
  description = "Elasticsearch 클러스터 이름"
}

variable "es_version" {
  type        = string
  default = "8.12.2"
  description = "Elasticsearch 버전"
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

variable "kibana_server" {
  type = object({
    ip       = string
    port     = number
    user     = string
    password = string
  })
  sensitive   = true
  description = "Kibana 를 실행할 서버 접속 정보"
  default = {
    ip       = "10.20.110.84"   # Kibana 서버 IP 입력
    port     = 50022
    user     = "dream"
    password = "Y8gjGveWi4Pg"
  }
}