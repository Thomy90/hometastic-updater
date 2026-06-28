#!/bin/bash
set -euo pipefail

[[ $EUID -eq 0 ]] || {
    echo "This script must be run as root."
    exit 1
}

command -v envsubst >/dev/null || {
    echo "envsubst is required (install gettext-base)."
    exit 1
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Deploying systemd service and timer..."

REPO_ROOT="$SCRIPT_DIR" envsubst \
    < "$SCRIPT_DIR/systemd/docker-update-queue.service.template" \
    > /etc/systemd/system/docker-update-queue.service

install -m 644 \
    "$SCRIPT_DIR/systemd/docker-update-queue.timer" \
    /etc/systemd/system/docker-update-queue.timer

systemd-analyze verify /etc/systemd/system/docker-update-queue.service
systemd-analyze verify /etc/systemd/system/docker-update-queue.timer

systemctl daemon-reload
systemctl enable --now docker-update-queue.timer
systemctl restart docker-update-queue.timer

echo
echo "Deployment completed successfully."
systemctl list-timers docker-update-queue.timer
