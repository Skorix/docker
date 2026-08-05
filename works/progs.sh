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

echo -e "${GREEN}=== Установка утилит (apt + прямые ссылки GitHub) ===${NC}"

# -------------------------------------------------------------------
# 1. Базовые зависимости через apt
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/6] apt: curl, wget, unzip, micro, btop, btm...${NC}"
apt update -y
apt install -y curl wget unzip micro btop btm

# -------------------------------------------------------------------
# 2. Fastfetch (прямая ссылка .deb)
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/6] fastfetch...${NC}"
if ! command -v fastfetch &> /dev/null; then
    DEB_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
    if wget -q --timeout=10 -O /tmp/fastfetch.deb "$DEB_URL"; then
        dpkg -i /tmp/fastfetch.deb || apt install -f -y
        rm -f /tmp/fastfetch.deb
        echo "fastfetch установлен."
    else
        echo -e "${RED}Не удалось скачать fastfetch${NC}"
    fi
else
    echo "fastfetch уже установлен."
fi

# -------------------------------------------------------------------
# 3. Gdu (прямая ссылка)
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/6] gdu...${NC}"
if ! command -v gdu &> /dev/null; then
    TMP_DIR=$(mktemp -d)
    URL="https://github.com/dundee/gdu/releases/latest/download/gdu_linux_amd64.tgz"
    if wget -q --timeout=10 -O "$TMP_DIR/gdu.tgz" "$URL"; then
        tar -xzf "$TMP_DIR/gdu.tgz" -C "$TMP_DIR"
        BIN=$(find "$TMP_DIR" -type f -executable -name "gdu*" | head -1)
        if [[ -n "$BIN" ]]; then
            cp "$BIN" /usr/local/bin/gdu
            chmod +x /usr/local/bin/gdu
            echo "gdu установлен."
        else
            echo -e "${RED}Бинарник gdu не найден.${NC}"
        fi
    else
        echo -e "${RED}Не удалось скачать gdu${NC}"
    fi
    rm -rf "$TMP_DIR"
else
    echo "gdu уже установлен."
fi

# -------------------------------------------------------------------
# 4. Dua – официальный install.sh (без API, без зависаний)
# -------------------------------------------------------------------
echo -e "${YELLOW}[4/6] dua...${NC}"
if ! command -v dua &> /dev/null; then
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    echo "Запускаю официальный установщик dua..."
    curl -LSfs https://raw.githubusercontent.com/Byron/dua-cli/master/ci/install.sh | \
        sh -s -- --git Byron/dua-cli --target x86_64-unknown-linux-musl --crate dua --tag v2.29.0
    if [[ -f "$HOME/.cargo/bin/dua" ]]; then
        cp "$HOME/.cargo/bin/dua" /usr/local/bin/
        chmod +x /usr/local/bin/dua
        echo "dua установлен."
    else
        echo -e "${RED}Не удалось найти бинарник dua.${NC}"
    fi
    cd - > /dev/null
    rm -rf "$TMP_DIR"
else
    echo "dua уже установлен."
fi

# -------------------------------------------------------------------
# 5. Yazi (прямая ссылка) + настройка micro
# -------------------------------------------------------------------
echo -e "${YELLOW}[5/6] yazi...${NC}"
if ! command -v yazi &> /dev/null; then
    TMP_DIR=$(mktemp -d)
    URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    if wget -q --timeout=10 -O "$TMP_DIR/yazi.zip" "$URL"; then
        unzip -q "$TMP_DIR/yazi.zip" -d "$TMP_DIR"
        BIN=$(find "$TMP_DIR" -type f -executable -name "yazi" | head -1)
        if [[ -n "$BIN" ]]; then
            cp "$BIN" /usr/local/bin/yazi
            chmod +x /usr/local/bin/yazi
            echo "yazi установлен."
        else
            echo -e "${RED}Бинарник yazi не найден.${NC}"
        fi
    else
        echo -e "${RED}Не удалось скачать yazi.${NC}"
    fi
    rm -rf "$TMP_DIR"
else
    echo "yazi уже установлен."
fi

# Настройка yazi для micro
if command -v micro &> /dev/null && command -v yazi &> /dev/null; then
    YAZI_CONFIG_DIR="$HOME/.config/yazi"
    mkdir -p "$YAZI_CONFIG_DIR"
    CONFIG_FILE="$YAZI_CONFIG_DIR/yazi.toml"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<EOF
[editor]
exec = "micro"
EOF
        echo "Создан конфиг yazi с редактором micro."
    elif ! grep -q 'exec = "micro"' "$CONFIG_FILE"; then
        echo -e "\n[editor]\nexec = \"micro\"" >> "$CONFIG_FILE"
        echo "Добавлена настройка micro в yazi.toml."
    else
        echo "yazi уже настроен на micro."
    fi
fi

# -------------------------------------------------------------------
# 6. Zellij (прямая ссылка)
# -------------------------------------------------------------------
echo -e "${YELLOW}[6/6] zellij...${NC}"
if ! command -v zellij &> /dev/null; then
    TMP_DIR=$(mktemp -d)
    URL="https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
    if wget -q --timeout=10 -O "$TMP_DIR/zellij.tar.gz" "$URL"; then
        tar -xzf "$TMP_DIR/zellij.tar.gz" -C "$TMP_DIR"
        BIN=$(find "$TMP_DIR" -type f -executable -name "zellij" | head -1)
        if [[ -n "$BIN" ]]; then
            cp "$BIN" /usr/local/bin/zellij
            chmod +x /usr/local/bin/zellij
            echo "zellij установлен."
        else
            echo -e "${RED}Бинарник zellij не найден.${NC}"
        fi
    else
        echo -e "${RED}Не удалось скачать zellij.${NC}"
    fi
    rm -rf "$TMP_DIR"
else
    echo "zellij уже установлен."
fi

# -------------------------------------------------------------------
# Финальное сообщение
# -------------------------------------------------------------------
echo -e "${GREEN}✅ Установка завершена!${NC}"
echo "Теперь доступны:"
echo "  micro, btop, btm (bottom), fastfetch, gdu, dua, yazi, zellij"
echo -e "${YELLOW}Для анализа диска:${NC}"
echo "  gdu /путь    — быстрый интерактивный режим"
echo "  dua i /путь  — интерактивный режим с навигацией до окончания сканирования"
echo -e "${YELLOW}Yazi настроен на использование micro.${NC}"
echo -e "${YELLOW}Если какая-то команда не найдена, перелогиньтесь или выполните: source ~/.profile${NC}"