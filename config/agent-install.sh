#!/bin/bash
# Wazuh Agent installation for Debian/Ubuntu
# Usage: WAZUH_MANAGER=<ip> sudo bash agent-install.sh

set -euo pipefail

WAZUH_VERSION="${WAZUH_VERSION:-4.7.5-1}"
WAZUH_MANAGER="${WAZUH_MANAGER:?Set WAZUH_MANAGER=<server-ip>}"
WAZUH_AGENT_NAME="${WAZUH_AGENT_NAME:-$(hostname)}"

if [[ $EUID -ne 0 ]]; then
  echo "[!] Must run as root" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PKG="wazuh-agent_${WAZUH_VERSION}_${ARCH}.deb"
URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/${PKG}"

echo "[+] Downloading Wazuh agent ${WAZUH_VERSION} for ${ARCH}"
wget -q "$URL" -O "/tmp/${PKG}"

echo "[+] Installing agent (manager=${WAZUH_MANAGER}, name=${WAZUH_AGENT_NAME})"
WAZUH_MANAGER="$WAZUH_MANAGER" WAZUH_AGENT_NAME="$WAZUH_AGENT_NAME" \
  dpkg -i "/tmp/${PKG}"

echo "[+] Enabling and starting service"
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[+] Status:"
systemctl status wazuh-agent --no-pager | head -10

echo "[OK] Agent installed. Check the manager dashboard — it should appear as 'Active'."
