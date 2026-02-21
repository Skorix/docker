#!/bin/bash
echo "Скачиваю альтернативный образ..."
docker pull huecker.io/giongto35/web-moonlight:latest

echo "Создаю локальный тег..."
docker tag huecker.io/giongto35/web-moonlight:latest giongto35/web-moonlight:latest

echo "Готово! Запускай docker compose up -d"

