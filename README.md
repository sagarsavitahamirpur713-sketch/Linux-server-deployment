# Linux Server Deployment

A minimal, production-style deployment of a Python web app on a Linux
server: **App (Flask) → Gunicorn → systemd → Nginx → HTTPS (Let's Encrypt)**.

This project is a template for understanding how real backend services
are actually deployed and kept running on a VPS (AWS EC2, DigitalOcean,
Azure VM, etc.) — not just "run app.py and hope it doesn't crash."

## Architecture

```
Browser (https://yourdomain.com)
        │
        ▼
   Nginx (port 443, terminates SSL)
        │  proxy_pass via unix socket
        ▼
   Gunicorn (managed by systemd, myapp.service)
        │
        ▼
   Flask app (app/main.py)
```

- **Nginx** — public-facing reverse proxy, handles HTTPS and routes
  traffic to the app.
- **systemd** — keeps Gunicorn running, restarts it automatically if it
  crashes or the server reboots.
- **Gunicorn** — production WSGI server that actually runs the Flask app
  (Flask's own dev server is never used in production).
- **Let's Encrypt / certbot** — issues and auto-renews the free TLS
  certificate for HTTPS.

## Folder structure

```
linux-server-deployment/
│
├── app/
│   ├── main.py            # Flask application
│   └── requirements.txt   # Python dependencies
│
├── systemd/
│   └── myapp.service      # keeps the app running as a background service
│
├── nginx/
│   └── myapp.conf         # reverse proxy + HTTPS config
│
├── scripts/
│   ├── deploy.sh           # pull latest code, reinstall deps, restart
│   └── backup.sh           # backup app folder, rotate old backups
│
├── .gitignore
├── README.md
└── LICENSE
```

## Skills needed before doing this project

| Area | What you should know | Why |
|---|---|---|
| Linux basics | users, permissions (`chmod`/`chown`), `systemctl`, package manager (`apt`) | Everything runs on the OS layer |
| Networking | ports, firewall (`ufw`), DNS (A record pointing to server IP) | App must be reachable and secured |
| SSH | key-based login, basic `scp`/`rsync` | How you'll access and push files to the server |
| Python | virtualenvs, pip, basic Flask | The app itself |
| systemd | writing a `.service` unit, `enable`/`start`/`status`/`restart` | Keeps the app alive |
| Nginx | server blocks, `proxy_pass`, reverse proxy concept | Public entry point + HTTPS termination |
| TLS/HTTPS | what certbot does, cert renewal | Secures traffic |
| Bash scripting | variables, `set -euo pipefail`, cron | Automates deploy/backup |
| Git | clone, pull, `.gitignore` | Version control + how deploy.sh updates code |

You already have AWS/DevOps fundamentals (Docker, Ansible, Terraform,
Jenkins/GitHub Actions) — this project is the "manual, no-container"
version of what those tools normally automate for you. Doing it by hand
once makes every DevOps tool make a lot more sense afterward.

## Setup steps (on a fresh Ubuntu server)

1. **Point DNS** — create an A record for `yourdomain.com` pointing to
   the server's public IP.
2. **Update the system and install packages**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install -y python3-venv python3-pip nginx git certbot python3-certbot-nginx
   ```
3. **Create a dedicated app user (don't run the app as root)**
   ```bash
   sudo adduser --system --group myapp
   sudo mkdir -p /opt/myapp
   sudo chown myapp:myapp /opt/myapp
   ```
4. **Clone the project into `/opt/myapp`**
   ```bash
   sudo -u myapp git clone <your-repo-url> /opt/myapp
   cd /opt/myapp
   ```
5. **Create the virtual environment and install dependencies**
   ```bash
   sudo -u myapp python3 -m venv venv
   sudo -u myapp venv/bin/pip install -r app/requirements.txt
   ```
6. **Install the systemd service**
   ```bash
   sudo cp systemd/myapp.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now myapp
   sudo systemctl status myapp
   ```
7. **Configure Nginx**
   ```bash
   sudo cp nginx/myapp.conf /etc/nginx/sites-available/myapp.conf
   sudo ln -s /etc/nginx/sites-available/myapp.conf /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   ```
8. **Enable HTTPS**
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```
   Certbot edits `myapp.conf` automatically to add the SSL lines and
   sets up auto-renewal via a systemd timer.
9. **Verify**
   ```bash
   curl https://yourdomain.com/health
   ```
10. **Automate future deploys and backups**
    ```bash
    chmod +x scripts/deploy.sh scripts/backup.sh
    ./scripts/deploy.sh
    ```
    Add `backup.sh` to cron for scheduled backups (see comment at the
    top of that file).

## Common exam/interview questions this project answers

- Why use Gunicorn instead of Flask's built-in server? *(dev server is
  single-threaded and not hardened for production traffic)*
- Why does systemd matter? *(auto-restart on crash/reboot — no manual
  babysitting)*
- Why put Nginx in front of Gunicorn? *(TLS termination, static file
  serving, buffering slow clients, single public entry point)*
- What does `proxy_pass` to a Unix socket do vs a TCP port? *(slightly
  faster, avoids exposing an extra port)*
