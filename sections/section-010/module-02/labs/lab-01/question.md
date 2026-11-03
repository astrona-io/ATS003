# Question

Solve this question on: `terminal`

## Scenario

Astronaut, this machine was built from a base image and still carries the generic name `ubuntu-2404-base`. It has just been given its role as the first Frankfurt web server, and it needs a proper identity: the name that lasts, the name shown to people, and the local entry in `/etc/hosts` that stops `sudo` and other tools from complaining about an unknown host.

## Tasks

1. **Static and live hostname.** Set this host's hostname to `web-srv1`. It must be both the stored name (in `/etc/hostname`) and the name the `hostname` command reports right now, with no reboot.

2. **Pretty hostname.** Set the human-readable "pretty" hostname (the free-form one `hostnamectl` shows) to exactly:

   ```
   Web Server 1 (Frankfurt)
   ```

3. **Local resolution.** Update `/etc/hosts` so the `127.0.1.1` line points at `web-srv1` instead of the old `ubuntu-2404-base` name.
