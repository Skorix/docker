#!/bin/bash

# =============================================
# Развёртывание 3proxy с Podman (rootless)
# =============================================

PORT=9999
CONTAINER_NAME=3proxy
IMAGE=ghcr.io/tarampampam/3proxy:1

# 1. Открыть порт в firewalld (если активен)
if systemctl is-active --quiet firewalld; then
    if ! sudo firewall-cmd --list-ports | grep -q "$PORT/tcp"; then
        echo "➜ Открываем порт $PORT/tcp в firewalld..."
        sudo firewall-cmd --permanent --add-port="$PORT/tcp"
        sudo firewall-cmd --reload
    else
        echo "✓ Порт $PORT/tcp уже открыт."
    fi
else
    echo "⚠️ firewalld не запущен, пропускаем настройку."
fi

# 2. Остановить и удалить старый контейнер (если есть)
podman stop "$CONTAINER_NAME" 2>/dev/null || true
podman rm "$CONTAINER_NAME" 2>/dev/null || true

# 3. Запустить контейнер (без --restart, управление через systemd)
podman run -d \
  --name="$CONTAINER_NAME" \
  -p "$PORT:3128/tcp" \
  -e "PROXY_LOGIN=asd" \
  -e "PROXY_PASSWORD=asd" \
  -e "SOCKS_PORT=" \
  "$IMAGE"

# 4. Создать каталог для пользовательских юнитов
mkdir -p ~/.config/systemd/user

# 5. Сгенерировать systemd-юнит
cd ~/.config/systemd/user
podman generate systemd --name "$CONTAINER_NAME" --files --new

# 6. Перезагрузить systemd для пользователя
systemctl --user daemon-reload

# 7. Включить и запустить юнит
systemctl --user enable --now "container-$CONTAINER_NAME.service"

# 8. Включить linger (чтобы контейнер стартовал при загрузке системы)
if ! loginctl show-user "$USER" | grep -q "Linger=yes"; then
    echo "➜ Включаем linger для пользователя $USER..."
    sudo loginctl enable-linger "$USER"
    echo "✓ Linger включён."
else
    echo "✓ Linger уже включён."
fi

# 9. Итог
echo "=================================================="
echo "✅ Контейнер $CONTAINER_NAME успешно развёрнут!"
echo "   - Работает в rootless-режиме (без sudo)"
echo "   - Автоматически перезапускается при падении"
echo "   - Запускается при загрузке системы"
echo "=================================================="
echo "Управление: systemctl --user start/stop/restart container-$CONTAINER_NAME.service"
echo "Проверка:   podman ps"