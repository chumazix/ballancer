FROM debian:bookworm-slim

# При необходимости раскомментируйте строки для зеркала Яндекс
# RUN sed -i 's/deb.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list.d/debian.sources && \
#     sed -i 's/security.debian.org/mirror.yandex.ru/g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    systemd \
    sudo \
    python3 \
    cron \
    keepalived \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY ansible/keys/id_rsa.pub /home/ansible/.ssh/authorized_keys
RUN chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 600 /home/ansible/.ssh/authorized_keys

RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

COPY lb2/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
