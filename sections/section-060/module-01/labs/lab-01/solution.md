# Solution: Repair a persistent NetworkManager profile

Run these commands as `student` inside the lab VM.

```bash
nmcli -f connection,ipv4 connection show lab-static
sudo nmcli connection modify lab-static ipv4.addresses 192.168.120.50/24 connection.autoconnect yes ipv4.never-default yes
sudo nmcli connection up lab-static
ip -br address show nm0
# After reboot and reconnect:
nmcli -f NAME,DEVICE connection show --active
ip -br address show nm0
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
