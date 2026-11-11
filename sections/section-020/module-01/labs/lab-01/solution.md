# Solution: Build a persistent active-backup bond

Run these commands as `student` inside the lab VM.

```bash
sudo ip link add bond0 type bond mode active-backup
for iface in dummy1 dummy2; do
  sudo ip link set "$iface" down
  sudo ip link set "$iface" master bond0
  sudo ip link set "$iface" up
done
sudo ip link set bond0 up
sudo tee /etc/netplan/99-lab-bond.yaml >/dev/null <<'CONFIG'
network:
  version: 2
  renderer: networkd
  ethernets:
    dummy1: {}
    dummy2: {}
  bonds:
    bond0:
      interfaces:
      - dummy1
      - dummy2
      parameters:
        mode: active-backup
CONFIG
sudo chmod 600 /etc/netplan/99-lab-bond.yaml
sudo netplan generate
sudo netplan apply
sleep 5
cat /proc/net/bonding/bond0
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
