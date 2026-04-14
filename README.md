# terraform-practice

scp -v -P 50022 -r "C:\Users\gkfn185.DREAMSE\Desktop\ParkHyunMIn\study\ElasticSearch\terraform-elastic-linux" dream@10.20.110.83:/home/dream/terraform

sudo chown dream:dream /home/dream/terraform



echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf 
sudo sysctl -p
sysctl vm.max_map_count


# 컨테이너 중지
sudo docker rm -f elasticsearch

# 기존 데이터 삭제 (이전 클러스터 UUID 제거)
sudo rm -rf /services/elasticsearch/data/*

# 권한 재설정
sudo chown -R 1000:1000 /services/elasticsearch/data
sudo chown -R 1000:1000 /services/elasticsearch/logs

docker logs elasticsearch | tail -20