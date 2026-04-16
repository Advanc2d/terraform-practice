terraform {
  required_version = ">= 1.7.0"

  required_providers {
    # SSH 원격 명령 실행 (cloud-init runcmd 대체)
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    # elasticsearch.yml, metricbeat.yml, setup.sh 파일 렌더링
    # (cloud-init write_files 대체)
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
