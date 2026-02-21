#!/bin/bash
# Пробуем скачать официальный образ через работающее зеркало
echo "Скачиваю официальный образ через зеркало..."
docker pull huecker.io/moonlight-stream/moonlight-chrome-wasmv2:latest

# Создаем тег, чтобы compose его подхватил
docker tag huecker.io/moonlight-stream/moonlight-chrome-wasmv2:latest ghcr.io/moonlight-stream/moonlight-chrome-wasmv2:latest

echo "Готово! Запускай docker compose up -d"
