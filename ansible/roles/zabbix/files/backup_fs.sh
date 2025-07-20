#!/bin/bash
set -e

SRC_DIR="/var/www/html"
DEST_DIR="/opt/backups/files"
DATE=$(date +%F)

mkdir -p "$DEST_DIR"

backup_path="$DEST_DIR/wiki_fs_$DATE.tar.gz"

tar czf "$backup_path" "$SRC_DIR" && \
  echo "[INFO] Backup файловой системы создан: $backup_path" || \
  { echo "[ERROR] Не удалось создать архив файловой системы"; exit 1; }
