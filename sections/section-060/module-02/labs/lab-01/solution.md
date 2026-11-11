# Solution: Repair merged Netplan configuration

Run these commands as `student` inside the lab VM.

```bash
sudo netplan get ethernets.np0
sudo cat /etc/netplan/90-lab.yaml /etc/netplan/99-lab-extra.yaml
sudo mv /etc/netplan/99-lab-extra.yaml /etc/netplan/99-lab-extra.yaml.disabled
sudo netplan generate
sudo netplan apply
sleep 3
ip -br address show np0
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
