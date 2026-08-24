# Chapter 4: Local Hostname Name Resolution

Whenever you change your static hostname, you must synchronize your local static translation table in "/etc/hosts". If you fail to do so, local system applications like "sudo" will throw name resolution warnings.

Priority search orders are configured inside "/etc/nsswitch.conf".

---

## Guided Practice Lab 4: Local Resolution

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-014
```
Gain root:
```bash
sudo -i
```

### Step 2: Map Static Lookup entries
Open "/etc/hosts" in your editor:
```bash
nano /etc/hosts
```
Add local mapping entry:
```text
127.0.1.1  prod-app-01
```
Verify lookups resolve locally without warnings:
```bash
ping -c 3 prod-app-01
```
Verify search priority (confirm that "files" precedes "dns"):
```bash
cat /etc/nsswitch.conf | grep hosts:
```
