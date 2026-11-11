#!/usr/bin/env bash
set -euo pipefail
sudo -u cadet ssh-keygen -t ed25519 -N '' -f /home/cadet/.ssh/id_ed25519
sudo install -d -m 700 -o pilot -g pilot /home/pilot/.ssh
sudo cp /home/cadet/.ssh/id_ed25519.pub /home/pilot/.ssh/authorized_keys
sudo chown pilot:pilot /home/pilot/.ssh/authorized_keys
sudo chmod 600 /home/pilot/.ssh/authorized_keys
sudo tee /home/cadet/.ssh/config >/dev/null <<'REFERENCE_FILE'
Host station
    HostName localhost
    User pilot
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
REFERENCE_FILE
sudo chown cadet:cadet /home/cadet/.ssh/config
sudo chmod 600 /home/cadet/.ssh/config
sudo -u cadet ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes station true
sudo -u cadet ssh -o ExitOnForwardFailure=yes -f -N -L 9090:127.0.0.1:8081 station
