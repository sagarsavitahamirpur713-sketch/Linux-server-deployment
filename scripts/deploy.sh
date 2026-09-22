#!/usr/bin/env bash
#
# deploy.sh
# ---------
# Pulls the latest code, installs dependencies, and restarts the app.
# Run this ON THE SERVER as the deploy/myapp user (not root, unless
# your permissions require sudo for the systemctl restart line).
#
# Usage: ./deploy.sh

set -euo pipefail   # stop the script on any error

APP_DIR="/opt/myapp"
VENV_DIR="$APP_DIR/venv"
REPO_BRANCH="main"

echo ">>> Deploying MyApp..."

cd "$APP_DIR"

echo ">>> Pulling latest code from git..."
git pull origin "$REPO_BRANCH"

echo ">>> Activating virtual environment..."
source "$VENV_DIR/bin/activate"

echo ">>> Installing/updating dependencies..."
pip install --upgrade pip
pip install -r app/requirements.txt

echo ">>> Restarting application service..."
sudo systemctl restart myapp

echo ">>> Reloading Nginx (in case config changed)..."
sudo nginx -t && sudo systemctl reload nginx

echo ">>> Deployment finished successfully."
