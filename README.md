# 📘 Развёртывание корпоративной вики-системы на базе MediaWiki

---

## 📌 Цель проекта

Развернуть и настроить инфраструктуру для корпоративного сервиса ведения документации с помощью MediaWiki, с обеспечением:

- отказоустойчивости (2 MediaWiki, балансировщик)
- мониторинга (Zabbix)
- резервного копирования (fs + БД)
- отказоустойчивой базы данных (PostgreSQL master/replica)

---

## 🗺️ Инфраструктура

| Компонент        | Назначение                                       |
|------------------|--------------------------------------------------|
| `nginx-lb`       | Балансировщик между двумя MediaWiki              |
| `mediawiki-1/2`  | Два экземпляра MediaWiki                         |
| `pg-master`      | Главный сервер PostgreSQL                        |
| `pg-replica`     | Реплика PostgreSQL (streaming replication)       |
| `backup-zabbix`  | Мониторинг Zabbix + резервное копирование        |

---

## 🧰 Используемые технологии

- **Terraform** — создание виртуальных машин в Yandex.Cloud
- **Ansible** — настройка всех компонентов
- **PostgreSQL** — СУБД для MediaWiki и Zabbix
- **MediaWiki** — веб-приложение для ведения документации
- **Zabbix** — система мониторинга
- **cron + shell** — резервное копирование

---

## 🚀 Шаги запуска

### 1. Поднять инфраструктуру в Яндекс.Облаке

```bash
cd Terraform
terraform init
terraform apply -var-file=terraform.tfvars
```

### 2. Подставить IP-адреса в `ansible/inventory.yaml`

Из `terraform output` → `external_ips`.

### 3. Настроить SSH-доступ в `group_vars/all.yml`

```yaml
ansible_user: ubuntu
ansible_ssh_private_key_file: ~/.ssh/minio
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
ansible_become: true
```

### 4. Выполнить настройку всех компонентов

```bash
cd ansible
ansible-playbook site.yml
```

---

## 💾 Резервное копирование

На машине `backup-zabbix` размещаются:

- `/usr/local/bin/backup_fs.sh` — создаёт архив `/var/www/html`
- `/usr/local/bin/backup_db.sh` — создаёт дамп БД `my_wiki` через `pg_dump`
- cron-задачи запускаются ежедневно в 03:00
- Бэкапы хранятся в `/opt/backups/files/` и `/opt/backups/db/`

---

## 📈 Мониторинг (Zabbix)

- Zabbix поднимается вместе с PostgreSQL и Apache (всё кодом, без ручной настройки).

- Ansible загружает схему в БД, кладёт конфиги (zabbix_server.conf, zabbix.conf.php).

- Веб-интерфейс сразу доступен на http://<ip_backup>/zabbix.

- Авторизация: Admin / zabbix.

- Автоматически через API создаётся:

  - hostgroup MediaWiki

  - хост nginx-lb (с агентом и web scenario)

  - web scenario проверки / MediaWiki

  - шаблон Linux by Zabbix agent

- триггеры:

  - HTTP code != 200 (CRIT)

  - Response time > 2000 ms (WARN, avg 5m)

  - Response time > 5000 ms (CRIT, avg 5m)

✨ Можно расширять правила — через Ansible-шаблоны добавлять новые web-scenario и триггеры.

👉 Можно добавить хосты вручную в интерфейсе, привязать шаблон `Template App HTTP Service`.


---

## 🔁 Репликация PostgreSQL

- Используется `pg_basebackup` и `standby.signal`
- Реплика получает изменения в режиме `hot standby`
- Проверка на мастере:

```bash
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

- Проверка на реплике:

```bash
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```

---

## ✅ Проверка отказоустойчивости

| Сценарий                               | Ожидаемое поведение                            |
|----------------------------------------|-------------------------------------------------|
| Выключение `mediawiki-1`               | Nginx продолжает работать с `mediawiki-2`      |
| Выключение `pg-master`                 | `pg-replica` готов к переключению              |
| Удаление контента MediaWiki            | Восстанавливается из `tar`-архива              |
| Удаление базы данных                   | Восстанавливается из `pg_dump`                 |

---

## 📦 Структура проекта

```text
Terraform/
├── main.tf
├── variables.tf
├── terraform.tfvars
├── providers.tf
├── outputs.tf
├── versions.tf

ansible/
├── inventory.yaml
├── ansible.cfg
├── group_vars/
│   └── all.yml
├── site.yml
├── roles/
│   ├── nginx/
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   ├── mediawiki/
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/apache-vhost.j2
│   ├── postgres/
│   │   ├── tasks/main.yml
│   │   └── handlers/main.yml
│   ├── zabbix/
│   │   ├── tasks/main.yml
│   │   ├── handlers/main.yml
│   │   └── templates/
│   │       ├── backup_fs.sh.j2
│   │       └── backup_db.sh.j2
│   └── common/
│       ├── tasks/main.yml   (установка zabbix-agent)
│       └── handlers/main.yml

```

---
## 📦 Схема проекта

```mermaid
graph TD
    A[👤 User] --> B[☁️ Интернет]
    B --> C[🧮 nginx-lb]
    C --> D1[🖥️ mediawiki-1]
    C --> D2[🖥️ mediawiki-2]
    D1 --> E[🛢️ pg-master]
    D2 --> E[🛢️ pg-master]
    E --> F[🛢️ pg-replica]

    G[🛡️ backup-zabbix]
    G --> E
    G --> D1
    G --> D2
    G --> C
    G --> F
```

---

## 🏁 Заключение

- Проект автоматизирует полноценную инфраструктуру для MediaWiki
- Реализованы все элементы: отказоустойчивость, мониторинг, бэкап
- Всё готово к демонстрации и реальному использованию

## Шаблоны
```
# ansible/group_vars/all.yml

#all.yml
ansible_user: ubuntu
ansible_ssh_private_key_file: ###
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
ansible_become: true
postgres_version: ###
pg_data_dir: ###

replication_user: ###
replication_password: ###

mediawiki_version: ###
sysadmin_user: ###
sysadmin_password: ###
sysadmin_db: ###

master_host: "{{ hostvars['pg-master'].ansible_host }}"

# Zabbix API 
zabbix_api_url: "http://{{ hostvars['backup-zabbix'].ansible_host }}/zabbix"
zabbix_api_user: ###
zabbix_api_password: ###
backup_ssh_known_hosts:
  - "{{ hostvars['mediawiki-1'].ansible_host }}"
  - "{{ hostvars['mediawiki-2'].ansible_host }}"

# Параметры веб-проверки
zabbix_http_check_name: "MediaWiki Front"
zabbix_http_check_url: "http://{{ hostvars['nginx-lb'].ansible_host }}/"
zabbix_http_check_delay: "1m"
zabbix_http_check_timeout: "10s"
zabbix_http_check_host: "nginx-lb"
zabbix_http_rt_warn_ms: 2000
zabbix_http_rt_crit_ms: 5000
```


# terraform/terraform.tfvars
```yc_cloud_id   = 
yc_folder_id  = 
yc_zone       = 
instance_image = 

ssh_public_key = ###
instance_user  = 
service_account_key_file = 

virtual_machines = {
  "nginx" = {
    vm_name   = "nginx-lb"
    hostname  = "nginx-lb"
    vm_cpu    = 2
    ram       = 2
    disk      = 30
    disk_name = "nginx-disk"
    role      = "nginx"
  },
  "mediawiki1" = {
    vm_name   = "mediawiki-1"
    hostname  = "mediawiki-1"
    vm_cpu    = 2
    ram       = 4
    disk      = 30
    disk_name = "mediawiki1-disk"
    role      = "mediawiki"
  },
  "mediawiki2" = {
    vm_name   = "mediawiki-2"
    hostname  = "mediawiki-2"
    vm_cpu    = 2
    ram       = 4
    disk      = 30
    disk_name = "mediawiki2-disk"
    role      = "mediawiki"
  },
  "pgmaster" = {
    vm_name   = "pg-master"
    hostname  = "pg-master"
    vm_cpu    = 2
    ram       = 4
    disk      = 30
    disk_name = "pgmaster-disk"
    role      = "postgres"
  },
  "pgreplica" = {
    vm_name   = "pg-replica"
    hostname  = "pg-replica"
    vm_cpu    = 2
    ram       = 4
    disk      = 30
    disk_name = "pgreplica-disk"
    role      = "postgres"
  },
  "zabbix" = {
    vm_name   = "backup-zabbix"
    hostname  = "backup-zabbix"
    vm_cpu    = 2
    ram       = 2
    disk      = 30
    disk_name = "zabbix-disk"
    role      = "zabbix"
  }
}
```



## Разработчики

**Алексей Потанин**   [e-mail](mailto:avpotanin@gmail.com)
GitHub: [project-mediawiki](https://github.com/potashka)