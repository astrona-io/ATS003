# Solution: Repair a persistent NetworkManager profile

Run these commands as `student` inside the lab VM.

Inspect the saved profile before changing it. `connection modify` edits the persistent settings; `connection up` activates them on `nm0`. Autoconnect allows activation after boot, while `ipv4.never-default` protects the management route.

```bash
nmcli -f connection,ipv4 connection show lab-static
sudo nmcli connection modify lab-static ipv4.addresses 192.168.120.50/24 connection.autoconnect yes ipv4.never-default yes
sudo nmcli connection up lab-static
ip -br address show nm0
# After reboot and reconnect:
nmcli -f NAME,DEVICE connection show --active
ip -br address show nm0
```

Compare `nmcli connection show lab-static` with `ip -br address show nm0`. Both must show the corrected address, and the old address must be gone. Ubuntu may persist this NetworkManager profile through Netplan rather than a keyfile. Reboot and check the active profile again; an address added with `ip` alone would not prove persistence.

Submit when the checks pass. Submission ends the environment.
