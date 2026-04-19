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

# Запуск node_exporter (если установлен)
if [ -f /usr/local/bin/node_exporter ]; then
    /usr/local/bin/node_exporter > /var/log/node_exporter.log 2>&1 &
fi

# Запуск nginx-prometheus-exporter (если установлен)
if [ -f /usr/local/bin/nginx-prometheus-exporter ]; then
    /usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri http://127.0.0.1:80/nginx_status > /var/log/nginx-exporter.log 2>&1 &
fi

# Запуск keepalived-exporter (если установлен)
if [ -f /usr/local/bin/keepalived-exporter ]; then
    /usr/local/bin/keepalived-exporter > /var/log/keepalived-exporter.log 2>&1 &
fi

# Держим контейнер активным
tail -f /dev/null
