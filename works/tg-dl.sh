#!/bin/bash
set -e

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2y8aip3DLo6xHS/bPv0rt7vfqt3Yxx7/JK1iooGziq gitlab-deploy"
APP_DIR="/opt/tg-dl"
APP_PORT=8888

# Docker
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
fi

# docker compose plugin
docker compose version &>/dev/null || apt-get update -qq && apt-get install -y docker-compose-plugin

# Папка и docker-compose.yml
mkdir -p "$APP_DIR"
cat > "$APP_DIR/docker-compose.yml" <<EOF
version: '3'
services:
  app:
    image: registry.gitlab.com/skorix/tg-dl:latest
    container_name: tg-dl
    restart: always
    ports:
      - "${APP_PORT}:${APP_PORT}"
EOF

# SSH ключ
mkdir -p ~/.ssh
grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null || echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "✅ Готово! Теперь запушите изменения в GitLab — деплой автоматический."