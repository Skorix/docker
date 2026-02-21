#!/bin/bash
echo "Очищаю старые ошибки..."
docker compose down
docker image prune -af

echo "Скачиваю образ напрямую с Docker Hub..."
docker pull moonlightstream/moonlight-chrome-wasmv2:latest

echo "Запускаю проект..."
docker compose up -d
