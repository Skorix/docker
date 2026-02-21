#!/bin/bash
echo "Скачиваю образ через облачное зеркало Timeweb..."
# Используем зеркало, которое работает в РФ без сбоев
docker pull dockerhub.timeweb.cloud/moonlightstream/moonlight-chrome-wasmv2:latest

echo "Создаю локальный тег..."
# Переименовываем, чтобы docker-compose его "узнал"
docker tag dockerhub.timeweb.cloud/moonlightstream/moonlight-chrome-wasmv2:latest ghcr.io/moonlight-stream/moonlight-chrome-wasmv2:latest

echo "Готово! Запускай docker compose up -d"
