#!/bin/bash

set -e

echo "=== Установка и настройка HAProxy ==="

# Проверка, что порты 8081 и 8082 доступны
if ! curl -s -o /dev/null http://localhost:8081; then
    echo "ВНИМАНИЕ: lb1 (порт 8081) не отвечает. HAProxy будет установлен, но бэкенды могут быть недоступны."
fi
if ! curl -s -o /dev/null http://localhost:8082; then
    echo "ВНИМАНИЕ: lb2 (порт 8082) не отвечает. HAProxy будет установлен, но бэкенды могут быть недоступны."
fi

# Установка HAProxy
if ! command -v haproxy &> /dev/null; then
    echo "Установка HAProxy..."
    sudo apt update
    sudo apt install -y haproxy
else
    echo "HAProxy уже установлен."
fi

# Резервное копирование конфигурации
if [ -f /etc/haproxy/haproxy.cfg ]; then
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d%H%M%S)
    echo "Создана резервная копия старой конфигурации."
fi

# Настройка HAProxy
echo "Настройка HAProxy..."
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

# Перезапуск HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

echo "=== HAProxy готов ==="
echo "Единая точка входа: http://$(hostname -I | awk '{print $1}'):80"
echo "Проверка: curl http://localhost:80"
