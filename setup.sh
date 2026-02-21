#!/bin/bash
# 1. Пытаемся скачать образ напрямую через зеркало huecker.io
echo "Скачиваю образ через зеркало..."
docker pull huecker.io/ipeit/moonlight-chrome-wasmv2:latest

# 2. Создаем локальный тег, чтобы docker-compose узнал этот образ
echo "Создаю локальный тег..."
docker tag huecker.io/ipeit/moonlight-chrome-wasmv2:latest ipeit/moonlight-chrome-wasmv2:latest

echo "Готово! Теперь можешь запускать docker compose up -d"
