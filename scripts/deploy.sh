#!/usr/bin/env bash

# deploy.sh
# ---------
# Production-style deployment script for MyApp.
#
# Flow:
# Git → Backup → Install dependencies → Validate app
# → Restart Gunicorn → Health check → Reload Nginx
#
# Usage:
#   ./deploy.sh

set -Eeuo pipefail

# --------------------------------------------------
# Configuration
# --------------------------------------------------

APP_NAME="myapp"
APP_DIR="/opt/myapp"
VENV_DIR="$APP_DIR/venv"
REPO_BRANCH="main"

HEALTH_URL="http://127.0.0.1:8000/health"

# --------------------------------------------------
# Logging
# --------------------------------------------------

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error_handler() {
    log "ERROR: Deployment failed at line $1."
}

trap 'error_handler $LINENO' ERR

# --------------------------------------------------
# Validation
# --------------------------------------------------

log "Starting deployment..."

if [[ ! -d "$APP_DIR" ]]; then
    log "ERROR: Application directory not found: $APP_DIR"
    exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
    log "ERROR: Virtual environment not found: $VENV_DIR"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    log "ERROR: Git is not installed."
    exit 1
fi

# --------------------------------------------------
# Move to application directory
# --------------------------------------------------

cd "$APP_DIR"

# --------------------------------------------------
# Check Git working tree
# --------------------------------------------------

log "Checking Git status..."

if [[ -n "$(git status --porcelain)" ]]; then
    log "ERROR: Working tree contains uncommitted changes."
    log "Commit or remove local changes before deployment."
    exit 1
fi

# --------------------------------------------------
# Pull latest code
# --------------------------------------------------

log "Fetching latest code..."

git fetch origin "$REPO_BRANCH"

LOCAL_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse origin/$REPO_BRANCH)"

if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
    log "Application is already up to date."
else
    log "Updating application..."
    git pull --ff-only origin "$REPO_BRANCH"
fi

# --------------------------------------------------
# Activate virtual environment
# --------------------------------------------------

log "Activating Python virtual environment..."

source "$VENV_DIR/bin/activate"

# --------------------------------------------------
# Upgrade dependencies
# --------------------------------------------------

log "Updating pip..."

python -m pip install --upgrade pip

log "Installing application dependencies..."

python -m pip install -r app/requirements.txt

# --------------------------------------------------
# Validate Flask application
# --------------------------------------------------

log "Checking Python application..."

python -m py_compile app/main.py

log "Python syntax check passed."

# --------------------------------------------------
# Restart application
# --------------------------------------------------

log "Restarting $APP_NAME service..."

sudo systemctl restart "$APP_NAME"

# --------------------------------------------------
# Verify systemd service
# --------------------------------------------------

log "Checking application service..."

if ! sudo systemctl is-active --quiet "$APP_NAME"; then
    log "ERROR: $APP_NAME service failed to start."

    sudo systemctl status "$APP_NAME" --no-pager || true

    exit 1
fi

log "Application service is running."

# --------------------------------------------------
# Health check
# --------------------------------------------------

log "Running application health check..."

HEALTH_CHECK_PASSED=false

for attempt in {1..10}; do

    if curl --fail --silent --show-error "$HEALTH_URL" >/dev/null; then
        HEALTH_CHECK_PASSED=true
        break
    fi

    log "Health check attempt $attempt failed. Retrying..."

    sleep 2

done

if [[ "$HEALTH_CHECK_PASSED" != true ]]; then
    log "ERROR: Application health check failed."
    exit 1
fi

log "Health check passed."

# --------------------------------------------------
# Validate and reload Nginx
# --------------------------------------------------

log "Testing Nginx configuration..."

sudo nginx -t

log "Reloading Nginx..."

sudo systemctl reload nginx

# --------------------------------------------------
# Deployment complete
# --------------------------------------------------

log "=========================================="
log "Deployment completed successfully!"
log "=========================================="
