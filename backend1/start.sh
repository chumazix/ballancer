#!/bin/sh

cron
/usr/sbin/sshd -D &

while [ ! -f /usr/sbin/nginx ]; do
    sleep 1
done
nginx &

while [ ! -f /usr/local/bin/node_exporter ]; do
    sleep 1
done
/usr/local/bin/node_exporter > /var/log/node_exporter.log 2>&1 &

tail -f /dev/null
