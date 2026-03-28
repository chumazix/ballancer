FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    systemd \
    && rm -rf /var/lib/apt/lists/*

# Создаём пользователя ansible с sudo без пароля
RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Копируем публичный ключ для доступа по SSH
COPY ansible/keys/id_rsa.pub /home/ansible/.ssh/authorized_keys
RUN chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 600 /home/ansible/.ssh/authorized_keys

# Настройка SSH
RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Директория для данных VictoriaMetrics
RUN mkdir -p /var/lib/victoriametrics /etc/victoriametrics

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
