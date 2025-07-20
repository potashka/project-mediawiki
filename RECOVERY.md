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

🛠 Восстановление:
```bash
sudo tar xzf /opt/backups/files/wiki_fs_<дата>.tar.gz -C /
sudo systemctl restart nginx
```

---

## 4. 🛢️ Удаление и восстановление базы данных

📍 Цель: восстановить базу данных из pg_dump

```bash
# Удаление БД:
sudo -u postgres psql -c "DROP DATABASE my_wiki;"
```

🛠 Восстановление:
```bash
gunzip -c /opt/backups/db/my_wiki_<дата>.sql.gz | sudo -u postgres psql my_wiki
```

---

