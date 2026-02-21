#!/bin/bash
# 1. Подготовка папки
echo "Подготовка окружения..."
docker compose down --remove-orphans
rm -rf ~/moonlight-web-dist
mkdir -p ~/moonlight-web-dist
cd ~/moonlight-web-dist

# 2. Скачивание официальной сборки (прямая ссылка на GitHub релиз)
echo "Загрузка официального релиза..."
wget https://github.com

# 3. Распаковка
echo "Распаковка..."
apt-get update && apt-get install unzip -y
unzip moonlight-chrome-wasmv2.zip

# 4. Запуск через Python (самый легкий способ)
echo "Запуск веб-сервера на порту 8080..."
# Убиваем старые процессы на этом порту, если они есть
fuser -k 8080/tcp 2>/dev/null
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "ГОТОВО! Плеер запущен."
echo "Заходи в браузере: http://$(hostname -I | awk '{print $1}'):8080"
