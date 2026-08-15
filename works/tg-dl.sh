#!/bin/bash
set -e

PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2y8aip3DLo6xHS/bPv0rt7vfqt3Yxx7/JK1iooGziq gitlab-deploy"
APP_DIR="/opt/tg-dl"
APP_PORT=8888

# 1. Установка Docker (если не установлен)
if ! command -v docker &>/dev/null; then
    echo "==> Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
else
    echo "✅ Docker уже установлен: $(docker --version)"
fi

# 2. Установка плагина docker compose (если не доступен)
if docker compose version &>/dev/null; then
    echo "✅ Плагин docker compose уже установлен"
else
    echo "==> Устанавливаем docker-compose-plugin через официальный репозиторий..."
    # Добавляем официальный репозиторий Docker
    apt-get update -qq
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y docker-compose-plugin
    echo "✅ Плагин установлен"
fi

# 3. Создаём папку и docker-compose.yml
mkdir -p "$APP_DIR"
if [ ! -f "$APP_DIR/docker-compose.yml" ]; then
    echo "==> Создаём docker-compose.yml в $APP_DIR"
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
else
    echo "✅ docker-compose.yml уже существует"
fi

# 4. Добавляем публичный SSH-ключ (если ещё не добавлен)
mkdir -p ~/.ssh
if ! grep -q "$PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "==> Добавляем публичный ключ в ~/.ssh/authorized_keys"
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
else
    echo "✅ Публичный ключ уже добавлен"
fi

echo "============================================="
echo "✅ Настройка завершена!"
echo "   - Docker: $(docker --version)"
echo "   - docker compose: $(docker compose version 2>/dev/null || echo 'установлен')"
echo "   - Папка приложения: $APP_DIR"
echo "   - Порт: $APP_PORT"
echo "   - Публичный ключ добавлен"
echo ""
echo "Теперь запушите изменения в GitLab — деплой автоматический."
echo "============================================="