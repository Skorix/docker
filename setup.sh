#!/bin/bash
# Настройка рабочих зеркал для Docker в РФ
sudo mkdir -p /etc/docker
echo '{
  "registry-mirrors": [
    "https://mirror.gcr.io",
    "https://daocloud.io",
    "https://huecker.io",
    "https://dockerhub.timeweb.cloud"
  ]
}' | sudo tee /etc/docker/daemon.json

# Перезапуск сервиса
sudo systemctl restart docker
echo "Зеркала настроены, Docker перезапущен!"
