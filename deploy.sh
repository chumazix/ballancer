#!/bin/bash

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Без цвета

echo -e "${GREEN}=== Развёртывание отказоустойчивой системы ===${NC}"

# 1. Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker не найден. Пожалуйста, установите Docker.${NC}"
    exit 1
fi

# 2. Проверка возможности запуска привилегированных контейнеров
echo -e "${YELLOW}Проверка доступности привилегированного режима...${NC}"
if docker run --rm --privileged alpine echo "OK" &> /dev/null; then
    PRIVILEGED=true
    COMPOSE_FILE="docker-compose.yml"
    echo -e "${GREEN}Привилегированный режим доступен. Используем конфигурацию с VIP.${NC}"
else
    PRIVILEGED=false
    COMPOSE_FILE="docker-compose.novip.yml"
    echo -e "${YELLOW}Привилегированный режим НЕ доступен. Используем конфигурацию без VIP (порты 8081, 8082).${NC}"
fi

# 3. Запуск контейнеров
echo -e "${GREEN}Запуск контейнеров с файлом $COMPOSE_FILE...${NC}"
docker compose -f $COMPOSE_FILE down -v 2>/dev/null || true
docker compose -f $COMPOSE_FILE up -d

# 4. Выполнение Ansible-плейбуков
echo -e "${GREEN}Выполнение Ansible-плейбуков...${NC}"
docker exec -it ansible bash -c "
cd /ansible && \
ansible-playbook -i inventory/hosts.ini playbooks/playbook_backend.yml && \
ansible-playbook -i inventory/hosts.ini playbooks/playbook_lb.yml && \
ansible-playbook -i inventory/hosts.ini playbooks/playbook_exporters.yml && \
ansible-playbook -i inventory/hosts.ini playbooks/playbook_monitoring.yml && \
ansible-playbook -i inventory/hosts.ini playbooks/playbook_cluster.yml
"

# 5. Перезапуск балансировщиков
echo -e "${GREEN}Перезапуск балансировщиков...${NC}"
docker restart lb1 lb2

# 6. Если привилегий нет, предложить установить HAProxy
if [ "$PRIVILEGED" = false ]; then
    echo -e "${YELLOW}VIP недоступен. Балансировщики доступны на портах: 8081 (lb1), 8082 (lb2).${NC}"
    echo -e "Для получения единой точки входа (порт 80) можно установить HAProxy."
    read -p "Установить и настроить HAProxy сейчас? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f ./setup_haproxy.sh ]; then
            ./setup_haproxy.sh
        else
            echo -e "${RED}Файл setup_haproxy.sh не найден. Пожалуйста, запустите его вручную позже.${NC}"
        fi
    else
        echo -e "Вы можете позже запустить ./setup_haproxy.sh вручную."
    fi
fi

echo -e "${GREEN}=== Развёртывание завершено ===${NC}"
echo -e "Проверка системы:"
if [ "$PRIVILEGED" = true ]; then
    echo "  VIP: curl http://172.20.0.100:80"
else
    echo "  Прямой доступ: curl http://localhost:8081 или curl http://localhost:8082"
fi
echo "  Grafana: http://<ip-хоста>:3000 (admin/admin)"
