# Summary

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the visitor's side of the airlock: the `ssh` client.

**From [Keys, ssh-copy-id And Known Hosts](./course-01-keys-and-known-hosts.md):**

- `ssh-keygen -t ed25519` makes a key pair: private key (keycard) and public key (lock).
- `ssh-copy-id -p <port> user@host` appends your public key to the remote `~/.ssh/authorized_keys`.
- `~/.ssh/known_hosts` stores the keys of ships you trust. `ssh-keygen -F` looks one up, and `ssh-keygen -R` removes one.

**From [The Client Configuration File](./course-02-the-client-configuration-file.md):**

- `~/.ssh/config` holds `Host` blocks with `HostName`, `User`, `Port`, `IdentityFile` and `ProxyJump`. It needs mode `600`.
- The first value found wins, so specific blocks go first.
- `ssh -G <name>` shows what `ssh` would use, and `ssh -v` shows how a login went.

**From [Tunnels Through The Channel](./course-03-tunnels.md):**

- `-L local:target` brings a far service to a local port, `-R` opens a port on the far ship, and `-D` makes a SOCKS proxy.
- `-f -N` runs a tunnel in the background without a command. `ss -tlnp` proves it is listening.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [OpenSSH Client Lab](./labs/lab-01/README.md) | Tunnels Through The Channel | create a key, install it, write a `Host` block, trust the host key and keep a tunnel open |

If you skipped it, go back to it now. It is short, and it tests the whole client workflow.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which file of a key pair may you share?</summary>

Only the public key, the file that ends in `.pub`. The private key stays on your ship.
</details>

<details>
<summary>2. <code>ssh</code> prints <code>REMOTE HOST IDENTIFICATION HAS CHANGED</code>. What do you do?</summary>

Find out whether the ship was really rebuilt. If it was, remove the old entry with `ssh-keygen -R` and accept the new key after checking its fingerprint. Never disable the check.
</details>

<details>
<summary>3. Two <code>Host</code> blocks set different ports for the same name. Which port is used?</summary>

The first one in the file. The first value found wins.
</details>

<details>
<summary>4. What does <code>-L 9090:127.0.0.1:8081</code> do?</summary>

It opens local port 9090. Traffic sent to it travels through the channel, and the far ship connects to its own `127.0.0.1:8081`.
</details>

<!-- astrona:playground:destroy -->
