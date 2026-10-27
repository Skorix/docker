#!/usr/bin/env bash
set -euo pipefail

TS6_DIR="/opt/teamspeak6"
CONTAINER_NAME="teamspeak6-server"
AUTO_CONFIRM=0

# Проверяем флаги
for arg in "$@"; do
  case $arg in
    -y|--yes) AUTO_CONFIRM=1 ;;
  esac
done

log() { echo -e "\n\033[1;34m[TS6]\033[0m $*"; }
warn() { echo -e "\n\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\n\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

install_docker() {
  if command -v docker &>/dev/null; then
    log "Docker уже установлен. Пропускаю."
    return 0
  fi

  log "Docker не найден. Устанавливаю..."

  if [[ -f /etc/debian_version ]]; then
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
    yum install -y -q yum-utils >/dev/null
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null
    yum install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
    systemctl enable --now docker
  else
    error "Неподдерживаемая ОС. Установи Docker вручную: https://docs.docker.com/engine/install/"
  fi

  log "Docker установлен."
}

cleanup_old() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    warn "Найден существующий контейнер ${CONTAINER_NAME}."
    
    if [[ -d "${TS6_DIR}/ts6-data" ]] && [ "$(ls -A ${TS6_DIR}/ts6-data 2>/dev/null)" ]; then
      warn "ВНИМАНИЕ: В папке ${TS6_DIR}/ts6-data есть данные (каналы, права, логи)."
      warn "При переустановке они будут УДАЛЕНЫ."
      
      if [[ ${AUTO_CONFIRM} -eq 0 ]]; then
        read -p "Продолжить и удалить старые данные? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          log "Отменено пользователем. Выход."
          exit 0
        fi
      fi
    fi

    log "Останавливаю и удаляю старый контейнер..."
    docker compose -f "${TS6_DIR}/docker-compose.yml" down --volumes --remove-orphans 2>/dev/null || \
      docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    
    log "Удаляю старые данные..."
    rm -rf "${TS6_DIR}/ts6-data"
  fi
}

deploy_ts6() {
  log "Подготовка директории: ${TS6_DIR}"
  mkdir -p "${TS6_DIR}"
  cd "${TS6_DIR}"

  cat > docker-compose.yml <<EOF
services:
  teamspeak6:
    image: teamspeaksystems/teamspeak6-server:latest
    container_name: ${CONTAINER_NAME}
    restart: unless-stopped
    ports:
      - "9987:9987/udp"   # Голосовой порт
      - "30033:30033/tcp" # Передача файлов
    environment:
      TSSERVER_LICENSE_ACCEPTED: "accept"
    volumes:
      - ./ts6-data:/var/tsserver/
EOF

  log "Скачиваю образ (если нужно) и запускаю контейнер..."
  docker compose up -d --pull always
}

get_privilege_key() {
  log "Ожидаю запуска и появления privilege key..."
  local key=""
  local retries=30

  while [[ ${retries} -gt 0 ]]; do
    sleep 2
    key=$(docker logs "${CONTAINER_NAME}" 2>&1 | grep -oE 'token=[A-Za-z0-9+/=_-]+' | head -n1 | cut -d= -f2 || true)
    if [[ -n "${key}" ]]; then
      break
    fi
    ((retries--))
  done

  if [[ -z "${key}" ]]; then
    error "Не удалось получить privilege key. Проверь логи: docker logs ${CONTAINER_NAME}"
  fi

  log "Готово! Твой ServerAdmin privilege key:"
  echo -e "\033[1;32m${key}\033[0m"
  echo -e "\n1. Скачай клиент TeamSpeak 6: https://teamspeak.com/en/downloads/"
  echo "2. Подключись к серверу по IP (порт 9987)."
  echo "3. Введи этот ключ при первом подключении — получишь права Server Admin."
}

main() {
  install_docker
  cleanup_old
  deploy_ts6
  get_privilege_key
}

main "$@"
