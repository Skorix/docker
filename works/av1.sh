#!/bin/bash
set -e

# === НАСТРОЙКА ===
PUBLIC_IP="${1:-147.45.216.75}"
MEET_PORT="${MEET_PORT:-8443}"

echo "=============================================="
echo " Установка Jitsi Meet (Docker) для IP: $PUBLIC_IP"
echo "=============================================="

# Установка необходимых системных утилит (wget, unzip), если их нет
if ! command -v wget &>/dev/null || ! command -v unzip &>/dev/null; then
    echo "Установка wget и unzip..."
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq wget unzip
    elif command -v yum &>/dev/null; then
        yum install -y -q wget unzip
    elif command -v dnf &>/dev/null; then
        dnf install -y -q wget unzip
    else
        echo "Ошибка: не удалось определить пакетный менеджер для установки wget/unzip."
        exit 1
    fi
fi

# Проверка Docker
if ! command -v docker &>/dev/null; then
    echo "Ошибка: Docker не установлен. Установите Docker и повторите попытку."
    exit 1
fi

# Определение команды Docker Compose
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "Ошибка: Docker Compose не найден."
    exit 1
fi

# Подготовка временного каталога
WORKDIR="./jitsi-meet-installation"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "1. Скачивание последней версии Jitsi Meet Docker..."
DOWNLOAD_URL=$(wget -q -O - https://api.github.com/repos/jitsi/docker-jitsi-meet/releases/latest | grep -o '"zipball_url": "[^"]*"' | grep -o 'https://[^"]*')
if [ -z "$DOWNLOAD_URL" ]; then
    echo "Ошибка: не удалось определить URL для скачивания."
    exit 1
fi
ZIP_FILE="jitsi-meet-latest.zip"
wget "$DOWNLOAD_URL" -O "$ZIP_FILE"

echo "2. Распаковка архива..."
unzip -q "$ZIP_FILE"
FOLDER=$(ls -d */ | head -1 | sed 's|/||')
cd "$FOLDER"

echo "3. Создание .env из примера..."
cp env.example .env

echo "4. Генерация надёжных паролей..."
chmod +x gen-passwords.sh
./gen-passwords.sh

echo "5. Создание необходимых каталогов конфигурации..."
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

echo "5a. Настройка прав доступа для контейнеров (UID 1000)..."
chown -R 1000:1000 ~/.jitsi-meet-cfg

echo "6. Настройка .env для работы по IP (без домена, без Let's Encrypt)..."
sed -i "s|^#\?\s*ENABLE_LETSENCRYPT=.*|ENABLE_LETSENCRYPT=0|" .env
sed -i "s|^#\?\s*PUBLIC_URL=.*|PUBLIC_URL=https://$PUBLIC_IP:$MEET_PORT|" .env
sed -i -E "s|^#?\s*JVB_ADVERTISE_IPS=.*|JVB_ADVERTISE_IPS=$PUBLIC_IP|" .env

echo "7. Запуск контейнеров Docker..."
$COMPOSE_CMD up -d

echo ""
echo "=============================================="
echo " Установка завершена успешно!"
echo " Веб-интерфейс: https://$PUBLIC_IP:$MEET_PORT"
echo "=============================================="
echo " Конфигурация: $(pwd)"
echo " Данные: ~/.jitsi-meet-cfg/"
echo ""
echo " Остановка: cd $(pwd) && $COMPOSE_CMD down"