#!/bin/bash
set -euo pipefail

# Copier le script VLAN switch
sudo cp /tmp/vlan-switch /usr/local/bin/vlan-switch
sudo chmod +x /usr/local/bin/vlan-switch

# Copier la config
sudo cp /tmp/vlan-switch.conf /etc/vlan-switch.conf
sudo chmod 644 /etc/vlan-switch.conf

# Copier le service systemd
sudo cp /tmp/vlan-switch.service /etc/systemd/system/vlan-switch.service
sudo chmod 644 /etc/systemd/system/vlan-switch.service

# Activer le service
sudo systemctl daemon-reload
sudo systemctl enable vlan-switch
sudo systemctl start vlan-switch
