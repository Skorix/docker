cd ~/cg/docker && \
curl -L -o moonlight.zip https://web.archive.org && \
unzip -o moonlight.zip && \
fuser -k 8080/tcp 2>/dev/null; \
nohup python3 -m http.server 8080 > /dev/null 2>&1 &
