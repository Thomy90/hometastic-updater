#!/bin/bash -e

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

(
    cd "$(dirname "$0")"

    echo "Deploying systemd service: diun"
    DIUN_ROOT=$(pwd) envsubst < diun.service.template > /etc/systemd/system/diun.service

    systemctl daemon-reload
    systemctl enable diun
    systemctl start diun

    echo "Service 'diun' has been deployed and started successfully."
)

