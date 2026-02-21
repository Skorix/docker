#!/bin/bash
echo "Полная очистка..."
fuser -k 8080/tcp 2>/dev/null
rm -rf ~/cg/docker/*
cd ~/cg/docker

echo "Загрузка реального архива (зеркало jsDelivr)..."
# Это зеркало отдает файл напрямую без редиректов GitHub
curl -L https://cdn.jsdelivr.net -o moonlight.zip

echo "Распаковка..."
# Если unzip нет, ставим его
apt-get update && apt-get install -y unzip
unzip -o moonlight.zip
rm moonlight.zip

echo "Проверка файлов..."
ls -lh index.html

echo "Запуск сервера..."
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "ГОТОВО! Обновляй страницу: http://147.45.216.75:8080"
