## Описание проекта

Проект реализует отказоустойчивую систему с балансировкой HTTP-трафика (Nginx + Keepalived), двумя бэкенд-серверами и централизованным мониторингом (VictoriaMetrics + Grafana). Вся установка и настройка автоматизирована через Ansible.

## Требования

- Docker и Docker Compose
- Git

## Развёртывание

1. Клонируйте репозиторий:
```bash
git clone <url> && cd ballancer 
```

2. Выполните следующие команды по порядку:
```bash
docker exec -it ansible bash
cd /ansible

ansible-playbook -i inventory/hosts.ini playbooks/playbook_backend.yml
ansible-playbook -i inventory/hosts.ini playbooks/playbook_lb.yml
ansible-playbook -i inventory/hosts.ini playbooks/playbook_exporters.yml
ansible-playbook -i inventory/hosts.ini playbooks/playbook_cluster.yml
ansible-playbook -i inventory/hosts.ini playbooks/playbook_monitoring.yml

exit
```

3. Дополнительная настройка для WSL или Вирутальных машин:
```bash
# Отключить rp_filter
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.default.rp_filter=0

# Найти bridge-интерфейс сети backend-net
BRIDGE=$(docker network inspect backend-net -f '{{ (index .Options "com.docker.network.bridge.name") }}')
if [ -n "$BRIDGE" ]; then
    sudo ip route add 172.20.0.100/32 dev $BRIDGE
fi
