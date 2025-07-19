#!/bin/bash
set -e

SRC="/var/www/html"
DEST="/opt/backups/files"
DATE=$(date +%F)

mkdir -p "$DEST"
tar czf "$DEST/wiki_fs_$DATE.tar.gz" "$SRC"

echo "[INFO] File system backup completed at $DEST/wiki_fs_$DATE.tar.gz"
