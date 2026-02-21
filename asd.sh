# 1. Удаляем "битый" файл
rm moonlight.zip

# 2. Скачиваем настоящий архив через curl с флагом -L (обязательно)
curl -L https://github.com -o moonlight.zip

# 3. Распаковываем (теперь ошибок быть не должно)
unzip -o moonlight.zip

# 4. Перезапускаем сервер, чтобы он увидел новые файлы (index.html и др.)
fuser -k 8080/tcp 2>/dev/null
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "Готово! Обновляй страницу в браузере."
