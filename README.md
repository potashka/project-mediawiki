# 📘 Развёртывание корпоративной вики-системы на базе MediaWiki

---

## 📌 Цель проекта

Развернуть и настроить инфраструктуру для корпоративного сервиса ведения документации с помощью MediaWiki, с обеспечением:

- отказоустойчивости (2 MediaWiki, балансировщик)
- мониторинга (Zabbix)
- резервного копирования (fs + БД)
- отказоустойчивой базы данных (PostgreSQL master/replica)

---

## 🗺️ Структура инфраструктуры

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

- Веб-интерфейс: `http://<ip_backup>/zabbix`
- Логин: `Admin` / Пароль: `zabbix`
- Мониторинг MediaWiki на уровне:
  - доступности HTTP (код + задержка)
  - состояния Zabbix-агентов на всех хостах

👉 Добавить хосты вручную в интерфейсе, привязать шаблон `Template App HTTP Service`.

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
│   │   └── tasks/main.yml + files/nginx.conf
│   ├── mediawiki/
│   │   └── tasks/main.yml
│   ├── postgres/
│   │   └── tasks/main.yml
│   ├── zabbix/
│   │   ├── tasks/main.yml
│   │   └── files/
│   │       ├── backup_fs.sh
│   │       └── backup_db.sh
│   └── common/
│       └── tasks/main.yml (установка zabbix-agent)
```

---
## Схема проекта

👤 [User] 
   ↓
☁️ [Интернет]
   ↓
🧮 [nginx-lb] — балансировщик
   ↓               ↓
🖥️ [mediawiki-1]   🖥️ [mediawiki-2]
     ↓                   ↓
🛢️ [pg-master]  ←  репликация  → 🛢️ [pg-replica]

           🔄 Streaming replication

🛡️ [backup-zabbix] — мониторинг + бэкап
     ↘ fs backup → [mediawiki-1]
     ↘ fs backup → [mediawiki-2]
     ↘ pg_dump   → [pg-master]

     ↘ мониторинг → [nginx-lb]
     ↘ мониторинг → [pg-replica]

---

## 🏁 Заключение

- Проект автоматизирует полноценную инфраструктуру для MediaWiki
- Реализованы все элементы: отказоустойчивость, мониторинг, бэкап
- Всё готово к демонстрации и реальному использованию

## Разработчики

**Алексей Потанин**   [avpotanin@gmail.com](mailto:avpotanin@gmail.com)
GitHub: [https://github.com/potashka](https://github.com/potashka)