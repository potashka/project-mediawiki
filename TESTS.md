# ✅ TESTS.md — Проверка работы системы после развертывания

Этот документ содержит базовый чеклист для ручного и полуавтоматического тестирования работы инфраструктуры MediaWiki после установки.

---

## 1. 📡 Проверка доступности компонентов

| Компонент        | Проверка                                   | Команда / Метод |
|------------------|---------------------------------------------|-----------------|
| nginx-lb         | Доступна главная страница MediaWiki         | curl http://<nginx-ip> |
| mediawiki-1      | Доступ по прямому IP                        | curl http://<ip> |
| mediawiki-2      | Доступ по прямому IP                        | curl http://<ip> |
| pg-master        | PostgreSQL доступен                         | psql -U wikiuser -d my_wiki -c '\dt' |
| pg-replica       | В режиме реплики                            | SELECT pg_is_in_recovery(); |
| zabbix           | Доступен веб-интерфейс                      | http://<zabbix-ip>/zabbix |

---

## 2. 🧪 Проверка работы MediaWiki

- Зайти на сайт через браузер.
- Создать тестовую статью.
- Проверить, что она сохраняется.
- Открыть статью по прямой ссылке.

---

## 3. 🔁 Проверка репликации PostgreSQL

### На `pg-master`:

```bash
psql -U wikiuser -d my_wiki -c "CREATE TABLE test_table (id INT);"
```

### На `pg-replica`:

```bash
psql -U wikiuser -d my_wiki -c "\dt"
```

✅ Таблица `test_table` должна появиться.

---

## 4. 💾 Проверка наличия бэкапов

📍 Проверка выполняется на ВМ backup-zabbix

```bash
ls -lh /opt/backups/files/
ls -lh /opt/backups/db/
```

✅ Должны быть `.tar.gz` и `.sql.gz` с текущей датой.

---

## 5. 📈 Проверка Zabbix

- Зайти в веб-интерфейс Zabbix: http://<zabbix-ip>/zabbix
- Авторизация: Admin / zabbix
- Проверить:
  - создан hostgroup `MediaWiki`
  - добавлен хост `nginx-lb` со статусом Online
  - прикреплён шаблон Linux by Zabbix agent
  - в разделе Monitoring → Latest Data видно метрики
  - в разделе Monitoring → Problems триггеры отрабатывают при ошибках (например, code != 200)

👉 Web scenario и триггеры создаются автоматически через API.

---

✅ Если всё выше успешно — система готова.
