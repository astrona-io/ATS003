# Question

Solve this question on: `terminal`

## Scenario

This machine was provisioned from a base image and still carries the generic
name `ubuntu-2404-base`. It has just been assigned its role as the first
Frankfurt web server, and needs a proper identity — the persistent name, the
name shown to humans, and the local-resolution entry that stops `sudo` and
other tools from complaining about an unknown host.

## Tasks

1. **Static + live hostname.** Set this host's hostname to `web-srv1`. It
   must be both the persisted name (in `/etc/hostname`) and the name
   reported right now by the `hostname` command — no reboot required.

2. **Pretty hostname.** Set the human-readable "pretty" hostname (the free-
   form one `hostnamectl` shows) to exactly:

   ```
   Web Server 1 (Frankfurt)
   ```

3. **Local resolution.** Update `/etc/hosts` so the `127.0.1.1` line points
   at `web-srv1` instead of the old `ubuntu-2404-base` name.
