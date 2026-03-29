FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y sudo \
    ansible \
    openssh-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN usseradd -m -s /bin/bass ansible && \
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

COPY ansible/keys/id_rsa /root/.ssh/id_rsa
COPY ansible/keys/id_rsa.pub /root/.ssh/id_rsa.pub
RUN chmod 600 /root/.ssh/id_rsa && \
    chmod 644 /root/.ssh/id_rsa.pub && \
    echo "StrictHostKeyChecking no" >> /root/.ssh/config

COPY ansible /ansible
WORKDIR /ansible

ENV ANSIBLE_CONFIG=/ansible/ansible.cfg

CMD ["sleep", "infinity"]
