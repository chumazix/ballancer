#!/bin/bash
set -e

echo "=== Проверка окружения ==="

# Проверяем, можем ли мы запустить привилегированный контейнер
if docker run --rm --privileged alpine true 2>/dev/null; then
    echo "Привилегированный режим доступен. Используем конфигурацию с VIP (Keepalived)."
    PRIVILEGED=true
else
    echo "Привилегированный режим НЕ доступен. Будет использована конфигурация без VIP (публикация портов)."
    PRIVILEGED=false
fi

if [ "$PRIVILEGED" = true ]; then
    echo "=== Запуск конфигурации с VIP ==="
    docker compose up -d
    docker exec -it ansible bash -c "
        cd /ansible && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_backend.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_lb.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_exporters.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_monitoring.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_cluster.yml
    "
    docker restart lb1 lb2
    echo "=== Развёртывание завершено (режим VIP) ==="
    echo "Проверка: curl http://172.20.0.100:80"
else
    echo "=== Запуск конфигурации без VIP (публикация портов) ==="
    # Используем альтернативный compose-файл
    docker compose -f docker-compose.novip.yml up -d
    # Выполняем плейбуки (они не требуют VIP)
    docker exec -it ansible bash -c "
        cd /ansible && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_backend.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_lb.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_exporters.yml && \
        ansible-playbook -i inventory/hosts.ini playbooks/playbook_monitoring.yml
    "
    # В режиме без VIP не запускаем playbook_cluster.yml (он для Keepalived)
    echo "=== Развёртывание завершено (режим без VIP) ==="
    echo "Балансировщики доступны по адресам: http://localhost:8081 и http://localhost:8082"
fi

