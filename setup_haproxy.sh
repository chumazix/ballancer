#!/bin/bash

# Скрипт для установки и настройки HAProxy на хосте
# Используется для объединения двух балансировщиков (порты 8081, 8082) в единый VIP на порту 80

set -e

echo "=== Установка HAProxy (если не установлен) ==="
if ! command -v haproxy &> /dev/null; then
    sudo apt update
    sudo apt install -y haproxy
else
    echo "HAProxy уже установлен"
fi

# Резервное копирование текущей конфигурации (если существует)
if [ -f /etc/haproxy/haproxy.cfg ]; then
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d%H%M%S)
    echo "Создана резервная копия конфигурации"
fi

echo "=== Настройка HAProxy ==="
sudo tee /etc/haproxy/haproxy.cfg > /dev/null <<EOF
global
    daemon
    maxconn 256

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend balancers

backend balancers
    balance roundrobin
    option httpchk GET /nginx_status
    server lb1 localhost:8081 check inter 2s rise 2 fall 3
    server lb2 localhost:8082 check inter 2s rise 2 fall 3
EOF

echo "=== Перезапуск HAProxy ==="
sudo systemctl restart haproxy
sudo systemctl enable haproxy

echo "=== Статус HAProxy ==="
sudo systemctl status haproxy --no-pager

echo ""
echo "HAProxy настроен и запущен"
echo "Единая точка входа: http://$(hostname -I | awk '{print $1}'):80"
echo "Теперь вы можете использовать команды из режима VIP:"
echo "  curl http://$(hostname -I | awk '{print $1}'):80"
echo ""
echo "Для проверки отказоустойчивости остановите один из балансировщиков:"
echo "  docker stop lb1"
echo "  curl http://$(hostname -I | awk '{print $1}'):80  # должен ответить бэкенд через lb2"
