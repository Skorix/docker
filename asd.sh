# 1. Заходим в папку проекта
cd ~/cg/docker

# 2. Скачиваем ПРАВИЛЬНЫЙ архив (именно релиз, а не страницу сайта)
curl -L https://github.com -o moonlight.zip

# 3. Распаковываем его в текущую папку
unzip -o moonlight.zip

# 4. Убиваем старый сервер и запускаем новый в этой же папке
fuser -k 8080/tcp 2>/dev/null
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "Теперь обнови страницу в браузере!"
