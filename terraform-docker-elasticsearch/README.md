# terraform-practice

scp -v -P 50022 -r "C:\Users\gkfn185.DREAMSE\Desktop\ParkHyunMIn\study\ElasticSearch\terraform-elastic-linux" dream@10.20.110.83:/home/dream/terraform

sudo chown dream:dream /home/dream/terraform

echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf 
sudo sysctl -p
sysctl vm.max_map_count


# 컨테이너 중지
sudo docker rm -f elasticsearch
sudo docker rm -f metricbeat

# 기존 데이터 삭제 (이전 클러스터 UUID 제거)
sudo rm -rf /services/elasticsearch/data/*
sudo rm -rf /services/metricbeat/logs/*

# 권한 재설정
sudo chown -R 1000:1000 /services/elasticsearch/data
sudo chown -R 1000:1000 /services/elasticsearch/logs
sudo chown -R 1000:1000 /services/metricbeat/logs

sudo docker rm -f kibana
sudo rm -rf /services/kibana/logs/*
sudo chown -R 1000:1000 /services/kibana/logs



docker logs elasticsearch | tail -20


curl http://10.20.110.80:9200/_cat/indices?v

health status index                                     uuid                   pri rep docs.count docs.deleted store.size pri.store.size dataset.size
green  open   .ds-.monitoring-es-8-mb-2026.04.14-000001 XwlSSNqIREaKo_cRtf4EbA   1   1        442            0      2.7mb          1.3mb        1.3mb
green  open   .ds-metricbeat-8.12.2-2026.04.14-000001   aGs7RrXTR0u5-9YC2QrHAQ   1   1       2840            0     12.2mb          4.5mb        4.5mb