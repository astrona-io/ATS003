#!/usr/bin/env bash
set -euo pipefail
sudo cp /etc/netplan/99-lab-bridge.yaml /tmp/lab-topology.saved
sudo python3 - <<'EDIT'
from pathlib import Path
import yaml
p=Path('/etc/netplan/99-lab-bridge.yaml')
data=yaml.safe_load(p.read_text())
data['network']['bridges']['br0']['interfaces'].remove('dummy0')
p.write_text(yaml.safe_dump(data,sort_keys=False))
EDIT
sudo netplan apply
sudo ip link set dummy0 nomaster
sleep 3
