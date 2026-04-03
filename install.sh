#!/bin/bash
set -euo pipefail

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi


cd "$(dirname "$0")"

echo "Stopping existing diun service (if any)..."
systemctl stop diun 2>/dev/null || true
systemctl disable diun 2>/dev/null || true

VERSION_FILE=".diun-version"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

if [[ -f "$VERSION_FILE" ]]; then
    VERSION=$(<"$VERSION_FILE")
    if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version in $VERSION_FILE"
        exit 1
    fi
    echo "Using pinned version: $VERSION"
    FILENAME="diun_${VERSION}_linux_${ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/crazy-max/diun/releases/download/v${VERSION}/${FILENAME}"
else
    echo "Fetching latest version via GitHub API..."
    # Dynamic discovery needed because filename includes version
    DOWNLOAD_URL=$(wget -qO- https://api.github.com/repos/crazy-max/diun/releases/latest \
        | grep "browser_download_url" \
        | grep "linux_${ARCH}.tar.gz" \
        | cut -d '"' -f 4)
    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "Failed to find a matching diun release for linux_${ARCH}"
        exit 1
    fi
fi

rm -f /usr/local/bin/diun

wget -qO- "${DOWNLOAD_URL}" \
  | tar -xz --strip-components=1 -C /usr/local/bin ./diun \
  || { echo "Download or extraction failed for $DOWNLOAD_URL"; exit 1; }

chmod +x /usr/local/bin/diun

echo "Deploying systemd service: diun"
DIUN_ROOT=$(pwd) envsubst < setup/diun.service.template > /etc/systemd/system/diun.service

systemctl daemon-reload
systemctl enable diun
systemctl start diun

echo "Installed diun version:"
/usr/local/bin/diun --version || true

echo "Service 'diun' has been deployed and started successfully."
