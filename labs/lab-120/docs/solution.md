# Solution

## Step 1: Install and enable firewalld

```bash
sudo dnf install -y firewalld   # RHEL-family; use zypper install firewalld on openSUSE
sudo systemctl enable --now firewalld
systemctl status firewalld
```

`enable --now` both starts firewalld immediately and creates the boot-persistence symlink in one command, the same pattern used for any systemd-managed service. Confirm `Active: active (running)` before moving on — every `firewall-cmd` command below talks to this running daemon over D-Bus, and fails outright if it isn't up.

## Step 2: Check the default zone and active zones

```bash
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
```

`--get-default-zone` reports which zone new connections/interfaces get assigned to when nothing else specifies one — typically `public` on a fresh install. `--get-active-zones` shows which zones currently have at least one interface or source bound to them, and which interface(s) each one owns — this is the actual live binding, not just the default.

```text
public
  interfaces: eth0
```

If your interface already shows under `public`, the assignment step below is a no-op confirmation rather than a change — check first rather than assuming.

## Step 3: Assign the interface to the public zone (if needed)

```bash
sudo firewall-cmd --zone=public --change-interface=eth0 --permanent
sudo firewall-cmd --reload
```

Check `man firewall-cmd` for `--change-interface` — like the service/port additions below, this has both a runtime effect (immediate) and needs `--permanent` to survive a reload; doing both together here keeps the interface assignment consistent across the reload you're about to trigger anyway. If the interface is already correctly bound (as confirmed in Step 2), skip this — running it anyway is harmless but unnecessary.

## Step 4: Permanently allow the https service

```bash
sudo firewall-cmd --zone=public --add-service=https --permanent
```

`--add-service=https` references firewalld's built-in service definition for `https` (a small XML file under `/usr/lib/firewalld/services/https.xml` describing "TCP port 443," among possibly other details) rather than you having to remember the raw port number — check `man firewalld.service` for the format if you ever need a custom one. `--permanent` writes this into the saved configuration under `/etc/firewalld/zones/public.xml` but, critically, does **not** apply it to the live runtime yet — this is deliberate on firewalld's part, so you can queue up several permanent changes before reloading once.

At this point, confirm the gap explicitly:

```bash
firewall-cmd --zone=public --list-services            # runtime — https NOT listed yet
firewall-cmd --zone=public --list-services --permanent # permanent — https IS listed
```

This is the exact runtime-vs-permanent split the lab is built around — seeing it side by side like this is worth doing deliberately at least once so the behavior isn't a surprise later.

## Step 5: Permanently allow the custom port 8443/tcp

```bash
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
```

Same pattern as the service addition, but for a raw port/protocol pair rather than a named service — use `--add-port` when there's no pre-defined service name (or when you deliberately don't want to allow the service's *other* associated behavior, if any) and `--add-service` when a suitable named service already exists and matches your intent.

## Step 6: Apply the permanent configuration to the runtime

```bash
sudo firewall-cmd --reload
```

This is the step that closes the gap from Step 4 — `--reload` re-reads the permanent configuration (both changes made above) and applies it to the live runtime, without restarting the firewalld process itself or dropping already-tracked connections the way `systemctl restart firewalld` might. Forgetting this step — believing the job is done because `--permanent` "sounds" like it should be enough — is the most common firewalld mistake there is.

## Step 7: Confirm runtime and permanent configuration now agree

```bash
firewall-cmd --zone=public --list-all
firewall-cmd --zone=public --list-all --permanent
```

Both outputs should now show `https` under `services` and `8443/tcp` under `ports`. If they don't match, something was added without `--permanent` (won't survive next reload) or added with `--permanent` but never applied via `--reload` (not active now) — re-check Steps 4–6 for whichever direction is missing.

## Verification

```bash
firewall-cmd --get-default-zone
# public

firewall-cmd --get-active-zones
# public
#   interfaces: eth0

firewall-cmd --zone=public --list-services
# ... https ...

firewall-cmd --zone=public --list-services --permanent
# ... https ...

firewall-cmd --zone=public --list-ports
# 8443/tcp

firewall-cmd --zone=public --list-ports --permanent
# 8443/tcp
```

Functional check from another host on the same subnet:

```bash
nc -zv 192.168.10.60 443
nc -zv 192.168.10.60 8443
```

Both should connect (assuming something is actually listening on those ports locally — firewalld only controls reachability, not whether a service is bound).

## Command Summary

```bash
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld

firewall-cmd --get-default-zone
firewall-cmd --get-active-zones

sudo firewall-cmd --zone=public --change-interface=eth0 --permanent

sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent

sudo firewall-cmd --reload

firewall-cmd --zone=public --list-all
firewall-cmd --zone=public --list-all --permanent
```
