#!/usr/bin/env bash
set -euo pipefail
sudo cp /etc/netplan/99-lab-bond.yaml /tmp/lab-topology.saved
sudo python3 - <<'EDIT'
from pathlib import Path
import yaml
p=Path('/etc/netplan/99-lab-bond.yaml')
data=yaml.safe_load(p.read_text())
data['network']['bonds']['bond0']['interfaces'].remove('dummy1')
p.write_text(yaml.safe_dump(data,sort_keys=False))
EDIT
sudo netplan apply
sudo ip link set dummy1 nomaster
sleep 3
