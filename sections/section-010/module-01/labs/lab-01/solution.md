# Solution: IPv4 and IPv6 addressing

Run these commands as `student` inside the lab VM.

The default route identifies the management interface. The additional Netplan file keeps DHCP enabled and adds the application addresses; replacing the DHCP address would break the SSH connection.

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

Compare `ip -br address` before and after applying the file. The management address must remain, alongside both new addresses. A ping to the local IPv6 address checks that it is assigned and usable on this host; it does not prove reachability from another machine. Reboot, reconnect, and repeat these checks to verify persistence.

Submit when the checks pass. Submission ends the environment.
