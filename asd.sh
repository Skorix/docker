#!/bin/bash
echo "Очистка старых файлов..."
rm -rf ~/moonlight-dist
mkdir -p ~/moonlight-dist
cd ~/moonlight-dist

echo "Загрузка официального релиза (v1.0.1)..."
# Используем curl -L, чтобы скачать сам файл, а не страницу GitHub
curl -L https://github.com -o moonlight.zip

echo "Распаковка..."
apt-get update && apt-get install -y unzip
unzip -o moonlight.zip
rm moonlight.zip

echo "Запуск веб-сервера..."
# Убиваем старый процесс, если он висит на 8080
fuser -k 8080/tcp 2>/dev/null
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "ГОТОВО! Плеер запущен по адресу: http://$(hostname -I | awk '{print $1}'):8080"

