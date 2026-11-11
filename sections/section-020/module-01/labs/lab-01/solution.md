# Solution: Build a persistent active-backup bond

Run these commands as `student` inside the lab VM.

The supplied dummy devices represent two available bond members. Take each member down before attaching it, then bring it up again. Active-backup mode selects one member at a time. The Netplan declaration recreates this topology after boot.

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

Check `/proc/net/bonding/bond0` for active-backup mode, both members and a currently active member. The dummy devices let you inspect membership and persistence; a physical link-failure exercise would need a different topology. Reboot and repeat these checks.

Submit when the checks pass. Submission ends the environment.
