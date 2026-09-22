#!/usr/bin/env bash

# backup.sh
# ---------
# Creates a compressed backup of the application directory.
# Keeps only the latest 7 backups.
#
# Usage:
#   ./backup.sh
#
# Cron example:
#   0 2 * * * /opt/myapp/scripts/backup.sh >> /var/log/myapp-backup.log 2>&1

set -Eeuo pipefail

# -----------------------------
# Configuration
# -----------------------------

APP_DIR="/opt/myapp"
BACKUP_DIR="/opt/myapp-backups"
KEEP_LAST=7

TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_FILE="$BACKUP_DIR/myapp-backup-$TIMESTAMP.tar.gz"

# -----------------------------
# Functions
# -----------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
    log "Backup failed."
}

trap cleanup ERR

# -----------------------------
# Validation
# -----------------------------

if [[ ! -d "$APP_DIR" ]]; then
    log "ERROR: Application directory does not exist: $APP_DIR"
    exit 1
fi

# -----------------------------
# Create backup directory
# -----------------------------

mkdir -p "$BACKUP_DIR"

# -----------------------------
# Create backup
# -----------------------------

log "Starting backup..."

tar \
    --exclude="$APP_DIR/venv" \
    --exclude="$APP_DIR/__pycache__" \
    --exclude="$APP_DIR/.git" \
    -czf "$BACKUP_FILE" \
    -C "$(dirname "$APP_DIR")" \
    "$(basename "$APP_DIR")"

# -----------------------------
# Verify backup
# -----------------------------

if [[ ! -s "$BACKUP_FILE" ]]; then
    log "ERROR: Backup file was not created correctly."
    exit 1
fi

log "Backup created successfully:"
log "$BACKUP_FILE"

# -----------------------------
# Remove old backups
# -----------------------------

log "Applying retention policy: keeping last $KEEP_LAST backups."

mapfile -t BACKUPS < <(
    ls -1t "$BACKUP_DIR"/myapp-backup-*.tar.gz 2>/dev/null || true
)

if (( ${#BACKUPS[@]} > KEEP_LAST )); then
    for old_backup in "${BACKUPS[@]:KEEP_LAST}"; do
        log "Removing old backup: $old_backup"
        rm -f -- "$old_backup"
    done
fi

# -----------------------------
# Final summary
# -----------------------------

log "Backup completed successfully."
log "Available backups:"

ls -lh "$BACKUP_DIR"/myapp-backup-*.tar.gz 2>/dev/null || \
    log "No backup files found.""
