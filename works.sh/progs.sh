#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Запускайте с sudo: sudo $0${NC}"
   exit 1
fi

echo -e "${GREEN}=== Установка: apt + бинарники для yazi и zellij ===${NC}"

# -------------------------------------------------------------------
# 1. Обновление и установка через apt
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/3] Установка через apt...${NC}"
apt update -y
apt install -y micro btop btm du-dust

# fastfetch – если есть в репозитории
if apt-cache show fastfetch &>/dev/null; then
    apt install -y fastfetch
else
    echo -e "${YELLOW}fastfetch не найден в apt, пропускаем.${NC}"
fi

# -------------------------------------------------------------------
# 2. Установка yazi (бинарник с GitHub)
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/3] Установка yazi...${NC}"
if ! command -v yazi &> /dev/null; then
    # Определяем архитектуру (поддерживаем amd64)
    ARCH="x86_64-unknown-linux-gnu"
    LATEST_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
        | grep "browser_download_url.*${ARCH}\.zip" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/yazi.zip" "$LATEST_URL"
        unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
        # Находим бинарник yazi и копируем в /usr/local/bin
        find "$TMP_DIR" -type f -executable -name "yazi" -exec cp {} /usr/local/bin/ \;
        chmod +x /usr/local/bin/yazi
        rm -rf "$TMP_DIR"
        echo "yazi установлен."
    else
        echo -e "${RED}Не удалось найти релиз yazi.${NC}"
    fi
else
    echo "yazi уже установлен."
fi

# -------------------------------------------------------------------
# 3. Установка zellij (бинарник с GitHub)
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/3] Установка zellij...${NC}"
if ! command -v zellij &> /dev/null; then
    # Для zellij используем musl-сборку (статическая, не требует glibc)
    ARCH="x86_64-unknown-linux-musl"
    LATEST_URL=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest \
        | grep "browser_download_url.*${ARCH}\.tar.gz" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/zellij.tar.gz" "$LATEST_URL"
        tar -xzf "$TMP_DIR/zellij.tar.gz" -C "$TMP_DIR"
        # В архиве обычно файл zellij
        find "$TMP_DIR" -type f -executable -name "zellij" -exec cp {} /usr/local/bin/ \;
        chmod +x /usr/local/bin/zellij
        rm -rf "$TMP_DIR"
        echo "zellij установлен."
    else
        echo -e "${RED}Не удалось найти релиз zellij.${NC}"
    fi
else
    echo "zellij уже установлен."
fi

# -------------------------------------------------------------------
# Финальное сообщение
# -------------------------------------------------------------------
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo "Доступны команды:"
echo "  micro, btop, btm (bottom), du-dust (dust), fastfetch (если был), yazi, zellij"
echo -e "${YELLOW}Если какая-то команда не найдена, перелогиньтесь или выполните:${NC}"
echo "  source ~/.profile"