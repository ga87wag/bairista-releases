#!/usr/bin/env bash
# bAIrista Gaggiuino Dashboard — one-command installer for Raspberry Pi OS Lite.
# Usage:  curl -fsSL https://raw.githubusercontent.com/ga87wag/bairista-releases/main/install.sh | bash
set -euo pipefail

APP="/opt/gaggiuino"
CORE_URL="https://github.com/ga87wag/bairista-releases/releases/download/core-v1/gaggiuino-core.tar.gz"
PORT="8080"
RUN_USER="${SUDO_USER:-$USER}"

echo "▸ Installing the bAIrista dashboard…"
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-pip curl

echo "▸ Downloading the dashboard…"
sudo mkdir -p "$APP"
sudo chown "$RUN_USER" "$APP"
curl -fsSL "$CORE_URL" -o /tmp/gaggiuino-core.tar.gz
tar -xzf /tmp/gaggiuino-core.tar.gz -C "$APP"

echo "▸ Installing Python dependencies…"
python3 -m venv "$APP/venv"
"$APP/venv/bin/pip" install --upgrade pip >/dev/null
"$APP/venv/bin/pip" install -r "$APP/requirements.txt"

echo "▸ Creating the service…"
sudo tee /etc/systemd/system/gaggiuino-dashboard.service >/dev/null <<UNIT
[Unit]
Description=bAIrista Gaggiuino Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$APP
ExecStart=$APP/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now gaggiuino-dashboard

echo ""
echo "✓ Done. Open the dashboard at:  http://$(hostname).local:$PORT"
echo "  (It looks for the machine at gaggiuino.local — set GAGGIUINO_URL in $APP/.env if yours differs.)"
