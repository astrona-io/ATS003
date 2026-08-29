# Overview: PLAYGROUND — OpenSSH Server Hardening (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh ssh-hardening-playground`.
- **A second, throwaway `sshd` on port 2222**, config file
  `/etc/ssh/sshd_test.conf`, managed by `sshd-test.service`. It is **self-contained**
  (does not `Include` the system drop-ins) and starts **wide open** —
  `PasswordAuthentication yes`, `PermitRootLogin yes`, `X11Forwarding yes` — so
  hardening it has a visible effect.
- **Two local test users**, playground-only credentials:
  - `alice` / `alicepass` — in group `sshusers`, has a key at
    `/home/alice/.ssh/id_ed25519`.
  - `bob` / `bobpass` — no key, password only.
- `ssh` / `ssh-keygen` client tools.

### The one rule

**Do not edit `/etc/ssh/sshd_config` or restart `ssh.service`.** Port 22 carries
your `astrona ssh` session; break it and you are locked out until
`astrona destroy` + `astrona run`. Everything below targets **port 2222** and
`sshd_test.conf`, which you can break freely.

The loop: edit `/etc/ssh/sshd_test.conf` → `sudo sshd -t -f /etc/ssh/sshd_test.conf`
(syntax check) → `sudo systemctl reload sshd-test` → test with `ssh -p 2222 …`.
Use `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null` on the test
`ssh` commands so a changed host key never blocks you.

## Things to try

- **Dump the effective config.** `sudo sshd -T -f /etc/ssh/sshd_test.conf` —
  every setting with its resolved value, including defaults you did not write.
- **Turn off password auth.** Set `PasswordAuthentication no`, reload, then:
  `ssh -p 2222 bob@localhost` (password only — now refused) vs
  `ssh -p 2222 -i /home/alice/.ssh/id_ed25519 alice@localhost` (key — still
  works).
- **Lock down root.** `PermitRootLogin no`, reload,
  `ssh -p 2222 root@localhost`.
- **Restrict who may log in.** `AllowUsers alice` (or `AllowGroups sshusers`),
  reload, then try `bob`.
- **Match blocks.** Append to the bottom:
  ```
  Match User bob
      PasswordAuthentication yes
      X11Forwarding no
  ```
  and see `bob` keep password auth while `alice` does not. Check with
  `sudo sshd -T -f /etc/ssh/sshd_test.conf -C user=bob,host=localhost,addr=127.0.0.1`.
- **Match by address.** `Match Address 127.0.0.1` vs `Match Address 10.0.0.0/8`.
- **Cut the brute-force surface.** `MaxAuthTries 2`, `LoginGraceTime 20`,
  `PermitEmptyPasswords no` — then watch `ssh -p 2222 -o PreferredAuthentications=password bob@localhost`
  with wrong passwords hit the limit.
- **Break it on purpose.** Put a typo in the file and run
  `sudo sshd -t -f /etc/ssh/sshd_test.conf` — see it caught before any reload.
- **Watch auth logs.** `sudo journalctl -u sshd-test -f` while you connect.
- **Drop-in style.** Add `Include /etc/ssh/sshd_test.d/*.conf` near the top and
  split settings into files there — how the real `/etc/ssh/sshd_config.d/` works.

## What this sandbox does not set up

- **fail2ban / sshguard**, 2FA, certificate auth, or a bastion topology — all
  worth knowing, none configured here.
- **A remote client.** You connect from the VM to itself over `localhost`.
- **Anything to grade.**

## When you're done

```sh
astrona destroy ssh-hardening-playground
```

(`astrona destroy` takes the environment name, not the config path.)
