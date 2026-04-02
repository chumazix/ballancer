FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    systemd \
    sudo \
    python3 \
    cron \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY ansible/keys/id_rsa.pub /home/ansible/.ssh/authorized_keys
RUN chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 600 /home/ansible/.ssh/authorized_keys

RUN mkdir /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22

CMD ["sh", "-c", "/usr/sbin/sshd -D & /usr/local/bin/victoria-metrics -storageDataPath=/var/lib/victoriametrics -httpListenAddr=:8428 -promscrape.config=/etc/victoriametrics/prometheus.yml & tail -f /dev/null"]
