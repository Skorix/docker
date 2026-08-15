#!/bin/bash
docker run -d --name speedtest_app -p 3000:3000 --restart unless-stopped openspeedtest/latest
echo "---"
echo "✅ Openspeedtest запущен на порту 3000."
echo "Проверьте статус командой 'docker ps -a' и откройте http://<IP-вашего-сервера>:3000"
echo "---"
