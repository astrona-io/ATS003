# Solution: Repair local hostname resolution

Run these commands as `student` inside the lab VM.

Start with `getent`, which uses the host lookup order from `/etc/nsswitch.conf`. Correct the existing `app-srv1` entry rather than adding another competing entry. The commands below leave unrelated host mappings in place.

```bash
sudo sed -i '/app-srv1/d' /etc/hosts
printf '%s\n' '192.168.10.71 app-srv1' | sudo tee -a /etc/hosts
getent hosts app-srv1
getent hosts 192.168.10.71
```

Both lookup directions should identify the same address/name pair. This checks the system name-service result, not network reachability. No interface address change is needed for a local hosts-file entry.

Submit when the checks pass. Submission ends the environment.
