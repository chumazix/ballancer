# Отказоустойчивая система с балансировкой и мониторингом

Проект реализует отказоустойчивую систему с балансировкой HTTP-трафика (Nginx + Keepalived), двумя бэкенд-серверами и централизованным мониторингом (VictoriaMetrics + Grafana). Вся установка и настройка автоматизирована через Ansible.

## Структура

- 7 Docker-контейнеров: `lb1`, `lb2`, `backend1`, `backend2`, `ansible`, `victoriametrics`, `grafana`.
- Изолированная сеть `backend-net` с подсетью `172.20.0.0/16`.
- VIP для балансировщиков: `172.20.0.100`.
- Сбор метрик: `node_exporter` (все узлы), `nginx-prometheus-exporter` (балансировщики).
- Визуализация: Grafana с предустановленным дашбордом.

## Требования

- Docker и Docker Compose
- Git

## Развёртывание

1. Клонируйте репозиторий:
```bash
git clone <url> && cd ballancer
# Доюавьте права если есть ошибка UNPROTECTED PRIVATE KEY FILE единоразово 
chmod 600 ansible/keys/id_rsa
# Запуск контейнеров иначе в них не зайти
docker compose up -d
# Смотря как установлен docker comopose
docker-compose up -d
```

2. Выполните эти команды для автоматического развертывания:
```bash
chmod +x deploy.sh
./deploy.sh
```
3. Выполните следующие команды по порядку(Ручное развертывание):
```bash
docker exec -it ansible bash
cd /ansible

ansible-playbook (-i /ansible/inventory/hosts.ini) playbooks/playbook_backend.yml
ansible-playbook playbooks/playbook_lb.yml
ansible-playbook playbooks/playbook_exporters.yml
ansible-playbook playbooks/playbook_monitoring.yml
ansible-playbook playbooks/playbook_cluster.yml
# В () указание инвентаря, чтобы избежать случайнрого применения не к тем хостам. Можно применять ко всем плейбукам
# В playbook_monitoring может быть ошибка, но на работу системы она не влияет

exit
```

4. Дополнительная настройка для Вирутальных машин 

# Если перезапускате контейнеры или работаете с сетью то нужно заново проходить шаг 2

```bash
# Отключить rp_filter
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.default.rp_filter=0

# Найти bridge-интерфейс сети backend-net
ip -4 addr show | grep -A 3 "br-"

# Найденый интерфейс из прошлой команды вставте вместо "br-..."
sudo ip route add 172.20.0.100/32 dev "br-..."
```
# Обязательно после настройки выполните ansible-playbook -i /ansible/inventory/hosts.ini playbooks/playbook_cluster.yml 

## Скринышоты дашбордов

![System Dashboard](screenshots/dashboard.png)

5. Проверка отказоустойчивости (кластеризация Keepalived)
```bash
# Определить, на каком балансировщике сейчас активен VIP
docker exec lb1 ip addr show | grep 172.20.0.100
docker exec lb2 ip addr show | grep 172.20.0.100

# Остановить активную ноду (например, если VIP на lb1)
docker stop lb1

# Убедиться, что VIP переключился на резервную ноду
docker exec lb2 ip addr show | grep 172.20.0.100

# Выполнить запрос через VIP – он должен пройти
curl http://172.20.0.100:80

# Восстановить остановленную ноду
docker start lb1
```
6. Проверка сбора метрик (VictoriaMetrics)
```bash
# Проверить, что все экспортеры доступны (значение 1)
docker exec ansible curl 'http://172.20.0.30:8428/api/v1/query?query=up' | grep -o '"value":\["[^"]*"\]'

# Проверить состояние VIP через keepalived-exporter (должно быть 1 или 2)
docker exec ansible curl 'http://172.20.0.30:8428/api/v1/query?query=keepalived_vrrp_state'
```
4. Проверка визуализации в Grafana

Открыть браузер и перейти по адресу http://<IP_хоста>:3000

Логин: admin, пароль: admin

В левом меню выбрать Dashboards → System Dashboard

Убедиться, что все панели отображают данные:

Статус балансировщиков – 1 (Активен) для обоих узлов.

Доступность бэкенд-нод – 1 (Доступен) для backend1 и backend2.

Нагрузка на ноды (CPU/RAM) – графики с данными.

Сетевой трафик (RX/TX) – графики.

Активные соединения Nginx – график.


