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

echo -e "${GREEN}=== Установка: apt + GitHub ===${NC}"

# -------------------------------------------------------------------
# 1. Базовые пакеты через apt
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/6] Установка через apt...${NC}"
apt update -y
apt install -y micro btop btm

# -------------------------------------------------------------------
# 2. Fastfetch (через .deb с GitHub)
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/6] Установка fastfetch...${NC}"
if ! command -v fastfetch &> /dev/null; then
    ARCH=$(dpkg --print-architecture)
    LATEST_DEB=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
        | grep "browser_download_url.*${ARCH}\.deb" | cut -d '"' -f 4)
    if [[ -n "$LATEST_DEB" ]]; then
        wget -q -O /tmp/fastfetch.deb "$LATEST_DEB"
        dpkg -i /tmp/fastfetch.deb || apt install -f -y
        rm -f /tmp/fastfetch.deb
        echo "fastfetch установлен."
    else
        echo -e "${RED}Не удалось найти .deb для fastfetch.${NC}"
    fi
else
    echo "fastfetch уже установлен."
fi

# -------------------------------------------------------------------
# 3. Gdu (интерактивный анализатор диска)
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/6] Установка gdu...${NC}"
if ! command -v gdu &> /dev/null; then
    LATEST_URL=$(curl -s https://api.github.com/repos/dundee/gdu/releases/latest \
        | grep "browser_download_url.*linux_amd64\.tgz" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/gdu.tgz" "$LATEST_URL"
        tar -xzf "$TMP_DIR/gdu.tgz" -C "$TMP_DIR"
        find "$TMP_DIR" -type f -executable -name "gdu" -exec cp {} /usr/local/bin/ \;
        chmod +x /usr/local/bin/gdu
        rm -rf "$TMP_DIR"
        echo "gdu установлен."
    else
        echo -e "${RED}Не удалось найти релиз gdu.${NC}"
    fi
else
    echo "gdu уже установлен."
fi

# -------------------------------------------------------------------
# 4. Dua (анализатор с возможностью навигации до завершения сканирования)
# -------------------------------------------------------------------
echo -e "${YELLOW}[4/6] Установка dua...${NC}"
if ! command -v dua &> /dev/null; then
    ARCH="x86_64-unknown-linux-gnu"
    LATEST_URL=$(curl -s https://api.github.com/repos/Byron/dua-cli/releases/latest \
        | grep "browser_download_url.*${ARCH}\.tar.gz" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/dua.tar.gz" "$LATEST_URL"
        tar -xzf "$TMP_DIR/dua.tar.gz" -C "$TMP_DIR"
        find "$TMP_DIR" -type f -executable -name "dua" -exec cp {} /usr/local/bin/ \;
        chmod +x /usr/local/bin/dua
        rm -rf "$TMP_DIR"
        echo "dua установлен."
    else
        echo -e "${RED}Не удалось найти релиз dua.${NC}"
    fi
else
    echo "dua уже установлен."
fi

# -------------------------------------------------------------------
# 5. Yazi (с настройкой редактора micro)
# -------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Установка yazi...${NC}"
if ! command -v yazi &> /dev/null; then
    ARCH="x86_64-unknown-linux-gnu"
    LATEST_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
        | grep "browser_download_url.*${ARCH}\.zip" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/yazi.zip" "$LATEST_URL"
        unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
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

# Настройка yazi для использования micro
if command -v micro &> /dev/null; then
    YAZI_CONFIG_DIR="$HOME/.config/yazi"
    mkdir -p "$YAZI_CONFIG_DIR"
    CONFIG_FILE="$YAZI_CONFIG_DIR/yazi.toml"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<EOF
[editor]
exec = "micro"
EOF
        echo "Создан конфиг yazi с редактором micro."
    else
        if ! grep -q 'exec = "micro"' "$CONFIG_FILE"; then
            echo -e "\n[editor]\nexec = \"micro\"" >> "$CONFIG_FILE"
            echo "Добавлена настройка micro в существующий yazi.toml."
        else
            echo "yazi уже настроен на micro."
        fi
    fi
else
    echo -e "${YELLOW}micro не найден, yazi будет использовать редактор по умолчанию.${NC}"
fi

# -------------------------------------------------------------------
# 6. Zellij
# -------------------------------------------------------------------
echo -e "${YELLOW}[6/6] Установка zellij...${NC}"
if ! command -v zellij &> /dev/null; then
    ARCH="x86_64-unknown-linux-musl"
    LATEST_URL=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest \
        | grep "browser_download_url.*${ARCH}\.tar.gz" | cut -d '"' -f 4 | head -1)
    if [[ -n "$LATEST_URL" ]]; then
        TMP_DIR=$(mktemp -d)
        wget -q -O "$TMP_DIR/zellij.tar.gz" "$LATEST_URL"
        tar -xzf "$TMP_DIR/zellij.tar.gz" -C "$TMP_DIR"
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
echo "  micro, btop, btm (bottom), fastfetch, gdu, dua, yazi, zellij"
echo -e "${YELLOW}Для анализа диска:${NC}"
echo "  gdu /путь    — классический интерактивный режим (очень быстрый)"
echo "  dua i /путь  — интерактивный режим с возможностью навигации до окончания сканирования"
echo -e "${YELLOW}Yazi настроен на использование micro.${NC}"
echo -e "${YELLOW}Если что-то не работает, перелогиньтесь или выполните: source ~/.profile${NC}"