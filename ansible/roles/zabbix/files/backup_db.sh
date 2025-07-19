#!/bin/bash
set -e

DB="my_wiki"
USER="wikiuser"
DEST="/opt/backups/db"
DATE=$(date +%F)

mkdir -p "$DEST"
pg_dump -U "$USER" "$DB" | gzip > "$DEST/wiki_db_$DATE.sql.gz"

echo "[INFO] Database backup completed at $DEST/wiki_db_$DATE.sql.gz"
