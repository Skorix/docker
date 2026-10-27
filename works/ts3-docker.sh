#!/usr/bin/env bash
set -euo pipefail

# --- Настройки ---
TS3_DIR="/opt/teamspeak"

# --- Вспомогательные функции ---
log() {
  echo -e "\n\033[1;34m[TS3]\033[0m $*"
}

error() {
  echo -e "\n\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}

# --- 1. Проверка и установка Docker ---
install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker уже установлен. Пропускаю."
    return 0
  fi

  log "Docker не найден. Начинаю установку..."

  if [[ -f /etc/debian_version ]]; then
    # Debian / Ubuntu
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg lsb-release >/dev/null
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
  elif [[ -f /etc/redhat-release ]]; then
    # RHEL / CentOS / Alma / Rocky
    yum install -y -q yum-utils >/dev/null
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null
    yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
    systemctl enable --now docker
  else
    error "Неподдерживаемая ОС. Установите Docker вручную: https://docs.docker.com/engine/install/"
  fi

  log "Docker успешно установлен."
}

# --- 2. Развертывание TS3 ---
deploy_ts3() {
  log "Подготовка директории: ${TS3_DIR}"
  mkdir -p "${TS3_DIR}"
  cd "${TS3_DIR}"

  log "Создаю docker-compose.yml..."
  cat > docker-compose.yml <<EOF
services:
  teamspeak:
    image: teamspeak:latest
    container_name: teamspeak-server
    restart: unless-stopped
    ports:
      - "9987:9987/udp"   # Голосовой порт
      - "30033:30033/tcp" # Передача файлов
    environment:
      TS3SERVER_LICENSE: "accept"
    volumes:
      - ./ts3-data:/var/ts3server
EOF

  log "Скачиваю образ и запускаю контейнер..."
  docker compose up -d
}

# --- 3. Получение токена ---
get_token() {
  log "Ожидаю запуска сервера и появления токена..."
  local token=""
  local retries=30

  while [[ ${retries} -gt 0 ]]; do
    # Ждем 2 секунды перед первой проверкой
    sleep 2
    token=$(docker logs teamspeak-server 2>&1 | grep -oE 'token=[A-Za-z0-9+/=_-]+' | head -n1 | cut -d= -f2 || true)
    
    if [[ -n "${token}" ]]; then
      break
    fi
    ((retries--))
  done

  if [[ -z "${token}" ]]; then
    error "Не удалось получить токен. Проверьте логи: docker logs teamspeak-server"
  fi

  log "Установка завершена! Ваш токен администратора:"
  echo -e "\033[1;32m${token}\033[0m"
  echo -e "\n1. Зайдите в клиент TS3.\n2. Подключитесь к серверу.\n3. Введите этот токен (логин оставьте пустым или введите serveradmin).\n4. После входа вы сможете задать пароль и настроить права."
}

# --- Основной сценарий ---
main() {
  install_docker
  deploy_ts3
  get_token
}

main "$@"
