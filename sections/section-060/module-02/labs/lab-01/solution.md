# Solution: Repair merged Netplan configuration

Run these commands as `student` inside the lab VM.

Inspect both YAML files and the merged result first. The later file adds an address because Netplan combines address sequences. Renaming it to a suffix other than `.yaml` removes that declaration from the input while keeping a copy for inspection.

```bash
sudo netplan get ethernets.np0
sudo cat /etc/netplan/90-lab.yaml /etc/netplan/99-lab-extra.yaml
sudo mv /etc/netplan/99-lab-extra.yaml /etc/netplan/99-lab-extra.yaml.disabled
sudo netplan generate
sudo netplan apply
sleep 3
ip -br address show np0
```

After `netplan generate` validates the files, `netplan apply` changes the live interface. Compare the merged address list with `ip -br address show np0`; both must contain only the intended address. The management configuration remains in its own existing file. Repeat the checks after reboot.

Submit when the checks pass. Submission ends the environment.
