#!/bin/bash
set -euo pipefail

sudo timedatectl set-timezone Europe/Brussels
sudo hostnamectl set-hostname fw

# IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-ipforward.conf >/dev/null

# Appliquer netplan (contourne le bug Vagrant)
sudo cp /tmp/01-fw-netplan.yaml /etc/netplan/01-fw-netplan.yaml
sudo chmod 600 /etc/netplan/01-fw-netplan.yaml
sudo chown root:root /etc/netplan/01-fw-netplan.yaml
# Supprimer les confs parasites générées
sudo rm -f /etc/netplan/50-vagrant.yaml

sudo netplan generate
sudo netplan apply

# nftables
sudo apt-get update
sudo apt-get install -y nftables tcpdump traceroute

sudo cp /tmp/nftables.conf /etc/nftables.conf
sudo systemctl enable --now nftables
sudo nft -f /etc/nftables.conf

echo "FW OK: netplan appliqué + nftables chargé."

# --- Swap (évite OOM pendant apt install) ---
if ! swapon --show | grep -q "/swapfile"; then
  sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

DEBIAN_FRONTEND=noninteractive apt-get install -y snort

# Snort config
rm -rf /etc/snort
cp -r /tmp/snort /etc/snort
chown -R root:root /etc/snort
# --- Fix chemins dynamiques Snort (Ubuntu Jammy) ---
sed -i 's|/usr/lib/snort_dynamicpreprocessor|/usr/lib/x86_64-linux-gnu/snort_dynamicpreprocessor|g' /etc/snort/snort.conf
sed -i 's|/usr/lib/snort_dynamicengine|/usr/lib/x86_64-linux-gnu/snort_dynamicengine|g' /etc/snort/snort.conf

# Service systemd Snort DMZ
cp /tmp/snort-dmz.service /etc/systemd/system/snort-dmz.service
chmod 644 /etc/systemd/system/snort-dmz.service

systemctl daemon-reload
systemctl enable snort-dmz
systemctl start snort-dmz

echo "FW OK: snort-dmz service"
#permet de voir le service snort  en start
systemctl --no-pager status snort-dmz || true
