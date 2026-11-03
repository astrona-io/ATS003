# Solution Walkthrough

You will make a key, install it on the station, write a `Host` entry and open a tunnel. Everything runs on the lab virtual machine's `terminal`, except grading.

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed `astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-04/labs/lab-01
```

There are four checks: `key-pair`, `key-installed`, `host-alias` and `tunnel`. Run it after each step and watch one more turn green.

---

## Step 1: Make the key pair

Open the visitor's shell and create the key:

```bash
sudo -iu cadet
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519
```

`ssh-keygen` writes the private key `id_ed25519` (mode `600`) and the public key `id_ed25519.pub`.

**Run the check**. `key-pair` now passes.

---

## Step 2: Install the public key

```bash
ssh-copy-id -p 2222 pilot@localhost
```

Type `yes` for the host key question, then the password `pilotpass`. `ssh-copy-id` adds your public key to `/home/pilot/.ssh/authorized_keys`, and `ssh` saves the host key into `~/.ssh/known_hosts`. Test it:

```bash
ssh -p 2222 pilot@localhost hostname
```

No password is asked.

**Run the check**. `key-installed` now passes.

---

## Step 3: Write the nickname

Create `~/.ssh/config` with this content:

```text
Host station
    HostName localhost
    User pilot
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
```

Then make the permissions safe and test it:

```bash
chmod 600 ~/.ssh/config
ssh -G station | grep -E '^(hostname|user|port) '
ssh -o BatchMode=yes station true && echo login-ok
```

**Run the check**. `host-alias` now passes.

---

## Step 4: Open the tunnel

```bash
ssh -f -N -L 9090:127.0.0.1:8081 station
ss -tlnp 'sport = :9090'
curl http://127.0.0.1:9090/
```

`-f` sends `ssh` to the background, `-N` runs no command. `curl` prints the web page.

**Run the check**. `tunnel` now passes, and all four checks are green. Submit from your own terminal.

---

## If a check stays red

- **`key-installed` fails.** The key was copied for another user or port. Check `sudo cat /home/pilot/.ssh/authorized_keys`.
- **`host-alias` fails but the login works by hand.** Check the permissions with `ls -l ~/.ssh/config`, and that `known_hosts` has the entry: `ssh-keygen -F '[localhost]:2222'`.
- **`tunnel` fails.** The tunnel stopped, or port 9090 was busy. Run `ss -tlnp 'sport = :9090'`. Start it again.
