# OpenSSH Server Hardening

Astronaut, every ship has an airlock, and on a Linux ship the airlock guard is `sshd`, the OpenSSH server. SSH (Secure Shell) is a sealed communications channel between two ships. Any `sshd` that can be reached from the internet gets a steady stream of automated login attempts: scanners trying common user names and password lists, day and night.

**Hardening** the server means taking away what those attempts rely on, and shrinking what a successful one could do. You change the guard's standing orders, `/etc/ssh/sshd_config`, and you add exceptions for single crew members with `Match` blocks. This module works through both.

## Learning objectives

After this module you can:

- Explain the threat that SSH hardening answers, and name the settings with the biggest effect.
- Read the effective configuration with `sshd -T`, and explain "first value wins" and the order of the `sshd_config.d/` drop-in files.
- Turn off password login and root login, and confirm that key login still works.
- Limit who may log in with `AllowUsers` or `AllowGroups`, and explain why an allow list beats a deny list.
- Write a `Match` block for an exception for one user or one address, and check it with `sshd -T -C`.
- Check a configuration with `sshd -t` and reload without locking yourself out.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **The shell.** You can open a shell, use `sudo` and edit a text file.
- **SSH as a user.** You have connected to a machine over SSH with a key before. The keyword syntax of `sshd_config`, `Match`, and the difference between key login and password login are explained as they come up.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine named `ssh-hardening-playground`. Open a shell on it with `astrona ssh ssh-hardening-playground`. It comes with a safety net:

- **A second, throwaway `sshd` on port 2222.** Its configuration file is `/etc/ssh/sshd_test.conf`, and `sshd-test.service` runs it. It does not `Include` the system drop-in files, and it starts **wide open**: `PasswordAuthentication yes`, `PermitRootLogin yes`, `X11Forwarding yes`. So every hardening step has a visible effect.
- **Two local test users**, with playground-only passwords: `alice` (password `alicepass`, in group `sshusers`, with a key at `/home/alice/.ssh/id_ed25519`) and `bob` (password `bobpass`, no key).
- The `ssh` and `ssh-keygen` client tools, and `sudo` with no password.

**Do not edit `/etc/ssh/sshd_config` or restart `ssh.service`.** Port 22 carries your `astrona ssh` session. A bad change there locks you out until you run `astrona destroy` and a fresh `astrona run`. Every command in this module targets port **2222** and `sshd_test.conf`, which you can break freely.

Your edit loop is: edit `/etc/ssh/sshd_test.conf`, run `sudo sshd -t -f /etc/ssh/sshd_test.conf`, run `sudo systemctl reload sshd-test`, then test with `ssh -p 2222 …`. The test `ssh` commands include `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`, so a changed host key never blocks you. On a real server the configuration file is the default one, and you do not need the `-f` option.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Why Harden And What Is Really In Effect](./course-01-why-harden-and-what-is-really-in-effect.md): the threat, the `sshd` command, and the effective configuration.
2. [Drop-Ins, Keys And Root](./course-02-drop-ins-keys-and-root.md): which value wins, and turning off passwords and root login.
3. [Who May Log In](./course-03-who-may-log-in.md): allow lists and the per-connection limits.
4. [Match Blocks And Safe Reloads](./course-04-match-blocks-and-safe-reloads.md): exceptions for one user, and catching errors before a reload.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md): what you learned, your mission, and cleaning up.

## Why this matters

The SSH airlock is how every administrator gets aboard, so it is also the first door an attacker tries. A few lines in `sshd_config` turn password guessing into wasted effort.

The exam checks the **effective** configuration, not what you typed. A setting can sit in the file and still do nothing, because another value won first. This module trains you to prove every change with `sshd -T`.
