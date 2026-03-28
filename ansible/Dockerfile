FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ansible \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Копируем приватный ключ для подключения к остальным контейнерам
COPY ansible/keys/id_rsa /root/.ssh/id_rsa
COPY ansible/keys/id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && \
    chmod 644 /root/.ssh/id_rsa.pub && \
    echo "StrictHostKeyChecking no" >> /root/.ssh/config

COPY ansible /ansible
WORKDIR /ansible

CMD ["sleep", "infinity"]
