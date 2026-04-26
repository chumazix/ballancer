# Отказоустойчивая система с балансировкой и мониторингом

Проект реализует отказоустойчивую систему с балансировкой HTTP-трафика (Nginx + Keepalived), двумя бэкенд-серверами и централизованным мониторингом (VictoriaMetrics + Grafana).  
**Работает в любом окружении** – на обычных серверах, VirtualBox, в облаках без поддержки привилегированных контейнеров.

## Структура

- 7 Docker-контейнеров: `lb1`, `lb2`, `backend1`, `backend2`, `ansible`, `victoriametrics`, `grafana`.
- Изолированная сеть `backend-net` с подсетью `172.20.0.0/16`.
- VIP для балансировщиков: `172.20.0.100` (если окружение позволяет).
- Если привилегированных контейнеров нет – автоматически используется альтернативный режим (порты `8081`, `8082`) с возможностью поднять единый вход через HAProxy.
- Сбор метрик: `node_exporter` (все узлы), `nginx‑prometheus‑exporter` (балансировщики), `keepalived‑exporter`.
- Визуализация: Grafana с предустановленным дашбордом.

## Быстрый старт (автоматическое развёртывание)

Этот способ подходит для **любого окружения** – скрипт сам определит возможности и выберет подходящую конфигурацию.

```bash
# 1. Клонируйте репозиторий
git clone https://github.com/chumazix/ballancer.git
cd ballancer

# 2. Сделайте скрипты исполняемыми
chmod +x deploy.sh setup_haproxy.sh

# 2.1. Проверка, что пользователь в группе docker
sudo usermod -aG docker $USER
newgrp docker

# 3. Запустите развёртывание
./deploy.sh

# 3.1. Дополнительно выставьте права на приватный ключ (убирает ошибку UNPROTECTED PRIVATE KEY FILE)
chmod 600 ansible/keys/id_rsa
```

**Что произойдёт?**
- Скрипт проверит, доступен ли привилегированный режим Docker.
- Если **да** – использует `docker-compose.yml` (единый VIP `172.20.0.100`).
- Если **нет** – использует `docker-compose.novip.yml` (порты `8081` и `8082`) и предложит автоматически настроить HAProxy для единого входа на порту 80.
- Затем выполнит все Ansible‑плейбуки (установка и настройка).
- Перезапустит балансировщики.

После завершения скрипта система **полностью готова к работе**.

## Ручное развёртывание (по шагам)

Если вы хотите контролировать каждый шаг самостоятельно, выполните:

```bash
# 1. Клонирование и права на ключ (см. выше)

# 2. Запуск контейнеров (выберите один из вариантов)
#   Вариант А – с VIP (требует привилегий)
docker compose up -d
#   Вариант Б – без VIP (порты 8081, 8082)
docker compose -f docker-compose.novip.yml up -d

# 3. Войдите в контейнер Ansible
docker exec -it ansible bash
cd /ansible

# 4. Выполните плейбуки в правильном порядке
ansible-playbook playbooks/playbook_backend.yml
ansible-playbook playbooks/playbook_lb.yml
ansible-playbook playbooks/playbook_exporters.yml
ansible-playbook playbooks/playbook_monitoring.yml
ansible-playbook playbooks/playbook_cluster.yml

# 5. Выйдите из контейнера и перезапустите балансировщики
exit
docker restart lb1 lb2
```

> **Примечания:** 
> - Параметр `-i /ansible/inventory/hosts.ini` указывается для первого плейбука, далее он запоминается. 
> - В плейбуке `playbook_monitoring.yml` возможна ошибка при остановке Grafana (она не влияет на работу системы).

## Дополнительная настройка для виртуальных машин 

Если вы запускаете систему на виртуальной машине или в WSL2, VIP может быть не виден с хоста (но будет работать из контейнера `ansible`). Чтобы исправить это:

```bash
# Отключить rp_filter (нужно один раз)
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.default.rp_filter=0

# Найти bridge-интерфейс сети backend-net
ip -4 addr show | grep -A 3 "br-"
#   Пример вывода: 5: br-7f3a2b1c0d4e: ... inet 172.20.0.1/16 ...
#   Запомните имя интерфейса (br-7f3a2b1c0d4e)

# Добавить маршрут до VIP через этот интерфейс
sudo ip route add 172.20.0.100/32 dev br-7f3a2b1c0d4e

# После добавления маршрута обязательно перезапустите плейбук cluster
docker exec -it ansible bash
cd /ansible
ansible-playbook -i inventory/hosts.ini playbooks/playbook_cluster.yml
exit
```

Если вы перезапускаете контейнеры (`docker restart lb1 lb2`) или перезагружаете хост, маршрут может сброситься – повторите команду `sudo ip route add ...`.

## Проверка работоспособности

### 1. Балансировка (единый VIP или через HAProxy)

```bash
curl http://172.20.0.100:80
```
**Ожидаемый результат:** «Бэкенд 1» или «Бэкенд 2» (при повторных запросах чередование).

Если вы в режиме без VIP и не настраивали HAProxy, используйте:
```bash
curl http://localhost:8081   # lb1
curl http://localhost:8082   # lb2
```

### 2. Кластеризация (отказоустойчивость)

```bash
# Определить активную ноду
docker exec lb1 ip addr show | grep 172.20.0.100
docker exec lb2 ip addr show | grep 172.20.0.100

# Остановить активную (например, lb1)
docker stop lb1

# Проверить, что VIP переключился
docker exec lb2 ip addr show | grep 172.20.0.100

# Запрос через VIP должен пройти
curl http://172.20.0.100:80

# Восстановить lb1
docker start lb1
./deploy.sh
```

> **Для режима без VIP:** 
> - `docker stop lb1` → порт 8081 станет недоступен, порт 8082 продолжит работать. 
> - При использовании HAProxy запросы автоматически пойдут на живую ноду.

### 3. Сбор метрик VictoriaMetrics

```bash
# Проверить, что все экспортеры доступны (значение 1)
docker exec ansible curl 'http://172.20.0.30:8428/api/v1/query?query=up' | grep -o '"value":\["[^"]*"\]'

# Проверить состояние VIP через keepalived-exporter (только в режиме с VIP)
docker exec ansible curl 'http://172.20.0.30:8428/api/v1/query?query=keepalived_vrrp_state'
```

**Ожидаемый результат:** для `up` – все значения `"1"`; для `keepalived_vrrp_state` – `1` (MASTER) или `2` (BACKUP).

### 4. Мониторинг Grafana

- Откройте браузер: `http://<IP-хоста>:3000`
- Логин: `admin`, пароль: `admin`
- Перейдите в **Dashboards → System Dashboard**

**Убедитесь, что все панели отображают данные:** 
- Статус балансировщиков – `1` (Активен) для обоих узлов. 
- Доступность бэкенд-нод – `1` (Доступен) для `backend1` и `backend2`. 
- Нагрузка на ноды (CPU/RAM) – графики с данными. 
- Сетевой трафик (RX/TX) – графики. 
- Активные соединения Nginx – график. 
- Состояние VIP-адреса – `MASTER` / `BACKUP` (в режиме с VIP) или отсутствует.

## Устранение неполадок

| Проблема | Решение |
|----------|---------|
| `UNPROTECTED PRIVATE KEY FILE` | Выполните `chmod 600 ansible/keys/id_rsa` (уже добавлено в инструкцию). |
| VIP не отвечает с хоста (но работает из контейнера ansible) | Добавьте маршрут (см. раздел «Дополнительная настройка для виртуальных машин»). |
| Keepalived не запускается | Убедитесь, что в `docker-compose.yml` для `lb1` и `lb2` есть `privileged: true`. Если вы в среде без привилегий, используйте режим без VIP. |
| HAProxy не стартует (порт 80 занят) | Остановите другой веб-сервер (`sudo systemctl stop apache2` или `nginx`) или измените порт в `setup_haproxy.sh` на другой (например, 8080). |

## Скриншоты дашбордов

![System Dashboard](screenshots/dashboard.png)




# 1. Установите зависимости
sudo apt install -y dbus-user-session uidmap

# 2. Остановите обычный Docker
sudo systemctl stop docker docker.socket containerd
sudo systemctl disable docker docker.socket containerd

# 3. Запустите установку rootless (от вашего пользователя)
dockerd-rootless-setuptool.sh install

# 4. Добавьте переменные окружения (в ~/.bashrc)
echo 'export PATH=/usr/bin:$PATH' >> ~/.bashrc
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock' >> ~/.bashrc
source ~/.bashrc

# 5. Запустите rootless Docker
systemctl --user start docker
systemctl --user enable docker
