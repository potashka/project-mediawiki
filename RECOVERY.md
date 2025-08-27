# 🔁 RECOVERY.md — План восстановления инфраструктуры

Этот файл содержит сценарии восстановления компонентов системы MediaWiki в случае различных сбоев.

---

## 1. ❌ Выход из строя одного экземпляра MediaWiki

📍 Цель: убедиться, что балансировщик продолжает обслуживать трафик

```bash
# На ВМ mediawiki-1:
sudo poweroff
```

✅ Проверить в браузере:
```
http://<nginx-lb-ip>/
```
✔ MediaWiki должна продолжать работать через mediawiki-2

---

## 2. ❌ Выход из строя PostgreSQL master

📍 Цель: продемонстрировать наличие реплики

```bash
# На ВМ pg-master:
sudo poweroff
```

🔍 Проверка на pg-replica:
```bash
sudo -u postgres psql -c "SELECT pg_is_in_recovery();"
```
✔ Должно вернуть `t` — реплика в режиме standby

---

## 3. 🧹 Удаление и восстановление директории MediaWiki

📍 Цель: восстановить /var/www/html из бэкапа

```bash
# На mediawiki-ноде:
sudo rm -rf /var/www/html
```

🛠 Восстановление (архив содержит абсолютные пути, распаковываем в корень):

```bash
sudo tar xzf /opt/backups/files/wiki_fs_<дата>.tar.gz -C /
sudo systemctl restart apache2
```

---

## 4. 🛢️ Удаление и восстановление базы данных

📍 Цель: восстановить базу данных из pg_dump на pg-master

```bash
# Удаление БД:
sudo -u postgres psql -c "DROP DATABASE my_wiki;"
```

🛠 Восстановление:
```bash
 sudo -u postgres psql -v ON_ERROR_STOP=1 -tc "SELECT 1 FROM pg_roles WHERE rolname='wikiuser';" | grep -q 1 || \
>   sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE ROLE wikiuser LOGIN;"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE my_wiki OWNER wikiuser TEMPLATE template0 ENCODING 'UTF8';"
gunzip -c /tmp/my_wiki.sql.gz | sudo -u postgres psql -v ON_ERROR_STOP=1 my_wiki

```


👉 Сначала проверьте список файлов и подставьте актуальную дату:

```bash
ls -lh /opt/backups/db/
```

Например, 
```bash
gunzip -c /opt/backups/db/my_wiki_2025-08-25.sql.gz | sudo -u postgres psql my_wiki
```
---

## 5. ♻️ Восстановление Zabbix

📍 Цель: при сбое убедиться, что Zabbix-сервер и БД можно восстановить из бэкапов.

```bash
# На backup-zabbix:
sudo systemctl restart zabbix-server apache2 postgresql
```

🛠 Если утеряна БД zabbix:

```bash
sudo -u postgres dropdb zabbix
gunzip -c /opt/backups/db/zabbix_<дата>.sql.gz | sudo -u postgres createdb -O zabbix zabbix && \
gunzip -c /opt/backups/db/zabbix_<дата>.sql.gz | sudo -u postgres psql zabbix
```

✅ После восстановления зайти в веб-интерфейс и убедиться, что web scenario и триггеры автоматически пересоздаются через Ansible playbook.