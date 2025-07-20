#!/bin/bash
set -e

DB_NAME="my_wiki"
DB_USER="wikiuser"
DEST_DIR="/opt/backups/db"
DATE=$(date +%F)

mkdir -p "$DEST_DIR"
BACKUP_PATH="$DEST_DIR/${DB_NAME}_$DATE.sql.gz"

pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_PATH" && \
  echo "[INFO] Backup базы данных создан: $BACKUP_PATH" || \
  { echo "[ERROR] Не удалось создать дамп БД"; exit 1; }
