## Описание проекта

Проект реализует отказоустойчивую систему с балансировкой HTTP-трафика (Nginx + Keepalived), двумя бэкенд-серверами и централизованным мониторингом (VictoriaMetrics + Grafana). Вся установка и настройка автоматизирована через Ansible.

## Требования

- Docker и Docker Compose
- Git

## Развёртывание

1. Клонируйте репозиторий:
   ```bash
   git clone <url> && cd ballancer





Добавление официального GPG-ключа Docker:

bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
Добавление репозитория Docker:

bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
Установка Docker Engine и Docker Compose:

bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Docker Compose установится как плагин, и его можно будет вызывать командой docker compose.

Настройка прав пользователя (опционально, но удобно):
Добавьте вашего пользователя в группу docker, чтобы запускать команды без sudo.

bash
sudo usermod -aG docker $USER
