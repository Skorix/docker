#!/bin/bash
set -euo pipefail

# Проверка root
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен запускаться от root (или через sudo)."
   exit 1
fi

# Пароль из аргумента
if [[ $# -eq 0 ]]; then
    echo "Укажите пароль для базовой аутентификации:"
    echo "  $0 <пароль>"
    exit 1
fi
PASS="$1"

# ----------------------------------------------------------------------
# 1. Очистка предыдущей установки
# ----------------------------------------------------------------------
if [[ -d /root/metube ]]; then
    cd /root/metube
    docker compose down --remove-orphans 2>/dev/null || true
    cd /
    rm -rf /root/metube
fi

# ----------------------------------------------------------------------
# 2. Установка Docker (если не установлен)
# ----------------------------------------------------------------------
install_docker() {
    echo "Установка Docker..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
}

if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker уже установлен."
fi

# ----------------------------------------------------------------------
# 3. Установка Docker Compose плагина (если отсутствует)
# ----------------------------------------------------------------------
if ! docker compose version &> /dev/null; then
    echo "Docker Compose плагин не найден. Устанавливаю вручную..."
    # Скачиваем последнюю версию плагина для Linux (amd64/arm64)
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x86_64" ;;
        aarch64) ARCH="aarch64" ;;
        *) echo "Неподдерживаемая архитектура: $ARCH"; exit 1 ;;
    esac
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${ARCH}" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
    # Проверяем
    if ! docker compose version &> /dev/null; then
        echo "Не удалось установить Docker Compose. Попробуйте установить вручную."
        exit 1
    fi
    echo "Docker Compose плагин установлен."
else
    echo "Docker Compose уже доступен."
fi

# ----------------------------------------------------------------------
# 4. Генерация хеша пароля
# ----------------------------------------------------------------------
echo "Генерация хеша пароля..."
HASH=$(docker run --rm caddy:alpine caddy hash-password --plaintext "$PASS" 2>/dev/null | tail -n1)
if [[ -z "$HASH" ]]; then
    echo "Ошибка: не удалось получить хеш пароля."
    exit 1
fi

# ----------------------------------------------------------------------
# 5. Создание структуры и файлов
# ----------------------------------------------------------------------
mkdir -p /root/metube/downloads
cd /root/metube

cat > docker-compose.yml <<EOF
services:
  metube:
    image: ghcr.io/alexta69/metube
    container_name: metube
    restart: unless-stopped
    environment:
      - URL_PREFIX=/
      - DELETE_FILE_ON_TRASHCAN=true
    volumes:
      - /root/metube/downloads:/downloads
    expose:
      - "8081"

  caddy:
    image: caddy:alpine
    container_name: caddy
    restart: unless-stopped
    ports:
      - "8089:8080"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
    depends_on:
      - metube
EOF

cat > Caddyfile <<EOF
{
    auto_https off
}

:8080 {
    basicauth * {
        admin $HASH
    }
    reverse_proxy metube:8081
}
EOF

# ----------------------------------------------------------------------
# 6. Запуск
# ----------------------------------------------------------------------
echo "Запуск контейнеров..."
docker compose up -d

sleep 3
if docker ps | grep -q metube && docker ps | grep -q caddy; then
    echo "✅ Установка завершена успешно!"
    echo "Сервис доступен по адресу: http://$(curl -s ifconfig.me):8089"
    echo "Логин: admin, пароль: (тот, что вы указали)"
else
    echo "⚠️ Что-то пошло не так. Проверьте логи:"
    docker compose logs
    exit 1
fi