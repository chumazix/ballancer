#!/bin/sh

# Отключаем rp_filter
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0

# Запускаем cron и sshd
cron
/usr/sbin/sshd -D &

# Ждём nginx
while [ ! -f /usr/sbin/nginx ]; do
    sleep 1
done
nginx &

# Ждём конфиг keepalived и запускаем
while [ ! -f /etc/keepalived/keepalived.conf ]; do
    sleep 1
done
keepalived -f /etc/keepalived/keepalived.conf &

# Запускаем экспортеры (если нужны)
while [ ! -f /usr/local/bin/node_exporter ]; do sleep 1; done
/usr/local/bin/node_exporter > /var/log/node_exporter.log 2>&1 &

while [ ! -f /usr/local/bin/nginx-prometheus-exporter ]; do sleep 1; done
/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri http://127.0.0.1:80/nginx_status > /var/log/nginx-exporter.log 2>&1 &

while [ ! -f /usr/local/bin/keepalived-exporter ]; do sleep 1; done
/usr/local/bin/keepalived-exporter > /var/log/keepalived-exporter.log 2>&1 &

# Держим контейнер активным
tail -f /dev/null
