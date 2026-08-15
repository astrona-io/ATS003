# Question

`web-srv1` was provisioned from a base image and still reports its original generic hostname instead of `web-srv1`. Set the static hostname to `web-srv1` so it is correct immediately and survives a reboot. Additionally set a separate, cosmetic display name of `Web Server 1 (Frankfurt)` for use in tools that show a friendlier label. Confirm both persist, confirm `/etc/hosts` still resolves the new hostname to the loopback-adjacent address correctly, and confirm the shell prompt and `hostname` command reflect the change without requiring unrelated services to be restarted.
