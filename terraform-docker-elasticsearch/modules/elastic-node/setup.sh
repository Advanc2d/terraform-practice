#!/bin/bash
# =============================================================
# cloud-init.yml 의 runcmd 를 Ubuntu 서버용 shell script 로 변환
# Terraform remote-exec provisioner 가 SSH 로 실행합니다.
# =============================================================
set -euo pipefail
exec > >(tee /tmp/es-setup.log) 2>&1

# ── [1] kernel tuning ─────────────────────────────────────────
# 원래 cloud-init runcmd "kernel tuning" 블록과 동일
echo "[1/5] kernel tuning..."
sudo swapoff -a
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.swappiness=1

# 재부팅 후에도 유지
grep -q "vm.max_map_count" /etc/sysctl.conf || echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
grep -q "vm.swappiness"    /etc/sysctl.conf || echo "vm.swappiness=1"         | sudo tee -a /etc/sysctl.conf

# 원래 write_files: /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf <<'LIMITS'
*              soft    nofile    65536
*              hard    nofile    65536
root           soft    nofile    65536
root           hard    nofile    65536
elasticsearch  -       nofile    65535
*              soft    nproc     65536
*              hard    nproc     65536
*              soft    memlock   unlimited
*              hard    memlock   unlimited
LIMITS

# ── [2] setup docker ──────────────────────────────────────────
# 원래: yum install docker  →  Ubuntu: apt-get install docker.io
echo "[2/5] setup docker..."
if ! command -v docker &>/dev/null; then
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
fi
docker --version
# ubuntu 사용자를 docker 그룹에 추가
# 원래: usermod -a -G docker ec2-user  →  Ubuntu: ec2-user 대신 ubuntu
sudo usermod -aG docker ubuntu-user || true

# ── [3] setup directories ─────────────────────────────────────
# 원래 cloud-init runcmd "setup directories" 블록과 동일
echo "[3/5] setup directories..."
sudo mkdir -p /services/elasticsearch/data
sudo mkdir -p /services/elasticsearch/logs
sudo mkdir -p /services/elasticsearch/config
sudo mkdir -p /services/metricbeat/logs
sudo mkdir -p /services/metricbeat/config
sudo chown -R 1000:0 /services/elasticsearch
sudo chown -R 1000:0 /services/metricbeat

# ── [4] docker build ──────────────────────────────────────────
# 원래: cd /services/elasticsearch && docker build . -t phm-elasticsearch:8.12.2
echo "[4/5] docker build..."
sudo docker build /services/elasticsearch -t phm-elasticsearch:${es_version}

# ── [5] docker run elasticsearch ─────────────────────────────
# 원래 cloud-init runcmd "docker build and run" 블록
# --net host: 서버 IP 를 그대로 사용하기 위해 유지 (EC2 때와 동일)
echo "[5/5] docker run elasticsearch..."
sudo docker rm -f elasticsearch 2>/dev/null || true
sudo docker run -d --name elasticsearch \
  --net host \
  --restart unless-stopped \
  -m ${memory_mb} \
  -v /services/elasticsearch/logs:/usr/share/elasticsearch/logs \
  -v /services/elasticsearch/data:/usr/share/elasticsearch/data \
  -v /services/elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
  -e "ES_JAVA_OPTS=${java_opts}" \
  phm-elasticsearch:${es_version}

echo "=== ES setup complete on $(hostname) ==="
