# Solution: Repair local hostname resolution

Run these commands as `student` inside the lab VM.

```bash
sudo sed -i '/app-srv1/d' /etc/hosts
printf '%s\n' '192.168.10.71 app-srv1' | sudo tee -a /etc/hosts
getent hosts app-srv1
getent hosts 192.168.10.71
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
