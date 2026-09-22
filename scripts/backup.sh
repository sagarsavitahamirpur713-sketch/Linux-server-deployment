#!/usr/bin/env bash
#
# backup.sh
# ---------
# Creates a timestamped tar.gz backup of the app directory and keeps
# only the last 7 backups. Schedule with cron, e.g. daily at 2 AM:
#   0 2 * * * /opt/myapp/scripts/backup.sh >> /var/log/myapp-backup.log 2>&1
#
# Usage: ./backup.sh

set -euo pipefail

APP_DIR="/opt/myapp"
BACKUP_DIR="/opt/myapp-backups"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/myapp-backup-$TIMESTAMP.tar.gz"
KEEP_LAST=7

mkdir -p "$BACKUP_DIR"

echo ">>> Creating backup: $BACKUP_FILE"
tar --exclude="$APP_DIR/venv" -czf "$BACKUP_FILE" -C "$(dirname "$APP_DIR")" "$(basename "$APP_DIR")"

echo ">>> Removing backups older than the last $KEEP_LAST..."
ls -1t "$BACKUP_DIR"/myapp-backup-*.tar.gz | tail -n +$((KEEP_LAST + 1)) | xargs -r rm --

echo ">>> Backup complete. Current backups:"
ls -lh "$BACKUP_DIR"
