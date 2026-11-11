# Solution: IPv4 and IPv6 addressing

Run these commands as `student` inside the lab VM.

```bash
iface=$(ip -4 route show default | awk 'NR==1{print $5}')
sudo tee /etc/netplan/99-lab-secondary.yaml >/dev/null <<REFERENCE_FILE
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: true
      addresses: [192.168.10.71/24, 'fd00:10::70/64']
REFERENCE_FILE
sudo chmod 600 /etc/netplan/99-lab-secondary.yaml
sudo netplan apply

sleep 3
ip -br address
ping -6 -c 1 fd00:10::70
# Reboot, reconnect, and repeat the checks.
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
