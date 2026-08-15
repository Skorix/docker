#!/bin/bash
set -e

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2y8aip3DLo6xHS/bPv0rt7vfqt3Yxx7/JK1iooGziq gitlab-deploy"
APP_DIR="/opt/tg-dl"
APP_PORT=1703

# Docker
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
    systemctl start docker && systemctl enable docker
fi

# docker compose plugin
if ! docker compose version &>/dev/null; then
    apt-get update -qq
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-compose-plugin
fi

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
    environment:
      - BOT_TOKEN=\${BOT_TOKEN}
      - ALLOWED_USER_ID=\${ALLOWED_USER_ID}
EOF

# SSH ключ
mkdir -p ~/.ssh
grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null || echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "✅ VPS настроен. Теперь запушьте изменения в GitLab."