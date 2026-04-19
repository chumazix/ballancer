#!/bin/sh

# Отключаем rp_filter (нужно для работы VIP)
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0

# Запускаем cron (для заданий @reboot) и sshd
cron
/usr/sbin/sshd -D &

# Ждём, пока Ansible установит nginx (бинарник появится)
while [ ! -f /usr/sbin/nginx ]; do
    sleep 1
done
nginx &

# Ждём, пока Ansible скопирует конфиг keepalived
while [ ! -f /etc/keepalived/keepalived.conf ]; do
    sleep 1
done
keepalived -f /etc/keepalived/keepalived.conf &

# Держим контейнер активным
tail -f /dev/null
