# Solution

## Step 0: Back up the config and confirm current state

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sshd -T | grep -iE 'x11forwarding|passwordauthentication|banner'
```

`sshd -T` prints the fully resolved effective configuration (as if for a connection matching no `Match` blocks) — a good baseline snapshot before you start changing anything, and a fast way to prove your edits actually took effect later.

## Step 1: Disable X11Forwarding globally

Edit `/etc/ssh/sshd_config` and set (or add, if absent):

```
X11Forwarding no
```

This must be a **global** directive — it applies to everyone, with no exception requested in the task, so it belongs above any `Match` block, in the main body of the file. `X11Forwarding no` prevents `ssh -X`/`ssh -Y` sessions from tunneling X11 traffic through the SSH connection at all, closing off a class of attacks where a compromised or malicious client-side X server could be leveraged against processes on the server.

## Step 2: Disable PasswordAuthentication globally, then re-enable it for elena

Still in the global section:

```
PasswordAuthentication no
```

Then, **after** all global directives, add a `Match` block:

```
Match User elena
    PasswordAuthentication yes
```

Check `man 5 sshd_config` and search `/Match` — the man page states verbatim that keywords inside a matched block "override those set in the global section of the config file," which is the exact rule this step depends on; worth confirming from the source rather than trusting recall on exam day.

The global `no` becomes the default for every account. The `Match User elena` block is evaluated only for connections where the authenticating username is exactly `elena`; when it matches, its `PasswordAuthentication yes` overrides the global `no` for that connection only, per OpenSSH's documented Match-block override behavior. Every other user — including victor — falls through to the global default and gets password auth disabled, which is precisely "for everyone but elena."

Indentation of directives inside a `Match` block is a readability convention, not a syntax requirement, but keep it consistent so the block's scope is visually obvious to the next person editing this file.

## Step 3: Enable the Banner for elena and victor only

Add a second `Match` block, after the first:

```
Match User elena,victor
    Banner /etc/ssh/sshd-banner
```

Check `man 5 sshd_config`, search `/Banner` — confirm it's listed among the keywords "matchable" inside `Match` blocks before relying on this pattern; not every directive is legal there, and the man page's `Match` section explicitly enumerates which ones are.

`Match User` accepts a comma-separated list, so one block covers both accounts — no need for two separate blocks. `Banner` is a Match-legal keyword, and since there's no global `Banner` directive set (the compiled-in default is effectively "none"), every user *other* than elena and victor continues to see no banner at all, while these two see the contents of `/etc/ssh/sshd-banner` before authentication.

Create the banner file's content (any text satisfies the task; a real environment would put a legal/warning notice here):

```bash
sudo tee /etc/ssh/sshd-banner > /dev/null <<'EOF'
Authorized access only. All activity may be monitored and logged.
EOF
```

## Step 4: Review the final structure

```bash
sudo grep -vE '^\s*#|^\s*$' /etc/ssh/sshd_config | tail -20
```

Expected shape (order matters — both `Match` blocks after all global lines):

```
X11Forwarding no
PasswordAuthentication no

Match User elena
    PasswordAuthentication yes

Match User elena,victor
    Banner /etc/ssh/sshd-banner
```

## Step 5: Syntax-test before touching the running daemon

```bash
sudo sshd -t
```

No output means success. Any output is a fatal syntax problem — fix it before proceeding. This is the single most important step in the whole lab: `sshd -t` parses the file exactly as the daemon would, without affecting the currently running `sshd` process or any existing sessions at all.

You can also dump the effective config for a hypothetical connection as a specific user to sanity-check `Match` resolution before reload:

```bash
sudo sshd -T -C user=elena,host=data-002,addr=192.168.10.80 | grep -iE 'passwordauthentication|banner'
sudo sshd -T -C user=victor,host=data-002,addr=192.168.10.80 | grep -iE 'passwordauthentication|banner'
```

This shows exactly what sshd would apply per user without needing a live test connection — `passwordauthentication yes` for elena, `passwordauthentication no` for victor, and `banner /etc/ssh/sshd-banner` for both.

## Step 6: Reload sshd — keep your current session open

```bash
sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh
```

The service unit is named `sshd` on RHEL-family distros and `ssh` on Debian/Ubuntu — try one, fall back to the other. `reload` (not `restart`) re-reads the config and applies it to new connections without dropping your current authenticated session, which is exactly the safety margin you want: if something is still wrong, your existing terminal remains your way back in.

**Do not close your current session yet.** Open a second terminal/connection to validate before you consider the change complete.

## Verification

From a separate session (do not close your first one until these pass):

```bash
# elena: password auth should still work
ssh -v elena@data-002
# expect the auth negotiation to offer/accept password, and login to succeed
# with password "elena"

# victor: password auth should now be rejected
ssh -v victor@data-002
# expect: "Permission denied (publickey)." — password method not offered/accepted

# Banner should appear before authentication for both elena and victor
ssh victor@data-002
# expect the banner text to print before the password prompt
```

Confirm X11Forwarding is off:

```bash
ssh -v elena@data-002 2>&1 | grep -i x11forwarding
```

Expect to see the negotiated value reflect `no` (X11 forwarding request refused/not offered), which you can also confirm directly:

```bash
sudo sshd -T | grep -i x11forwarding
```

```text
x11forwarding no
```

## Command Summary

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sshd -T | grep -iE 'x11forwarding|passwordauthentication|banner'

sudo $EDITOR /etc/ssh/sshd_config
# global section:
#   X11Forwarding no
#   PasswordAuthentication no
# after all global lines:
#   Match User elena
#       PasswordAuthentication yes
#
#   Match User elena,victor
#       Banner /etc/ssh/sshd-banner

sudo tee /etc/ssh/sshd-banner > /dev/null <<'EOF'
Authorized access only. All activity may be monitored and logged.
EOF

sudo sshd -t
sudo sshd -T -C user=elena,host=data-002,addr=192.168.10.80 | grep -iE 'passwordauthentication|banner'
sudo sshd -T -C user=victor,host=data-002,addr=192.168.10.80 | grep -iE 'passwordauthentication|banner'

sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh

ssh -v elena@data-002
ssh -v victor@data-002
```
