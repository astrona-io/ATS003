# OpenSSH Client: Keys, Config And Tunnels

Astronaut, the last module taught you to guard an airlock. This one teaches you to be the visitor who knocks. The **OpenSSH client**, the `ssh` command, opens a sealed communications channel from your ship to another ship. You will learn to prove who you are with a keycard instead of a password, to remember the ships you trust, to give long commands a short nickname, and to carry other traffic through the channel.

## Learning objectives

After this module you can:

- Create an SSH key pair with `ssh-keygen` and explain which half is private and which half is public.
- Install your public key on a remote account with `ssh-copy-id` and log in without a password.
- Explain what `~/.ssh/known_hosts` protects you from, and fix a "host key changed" warning the right way with `ssh-keygen -R`.
- Write `~/.ssh/config` entries (`Host`, `HostName`, `User`, `Port`, `IdentityFile`, `ProxyJump`) and prove what `ssh` will really use with `ssh -G`.
- Open a local port forward (`-L`), a remote port forward (`-R`) and a dynamic forward (`-D`), and check them with `ss`.
- Reach a ship through a jump host with `ssh -J`.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **The shell.** You can open a shell, edit a text file and use `sudo`.
- **Ports.** A port is a radio channel on a ship's antenna. The SSH server listens on port 22 by default.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell with `astrona ssh ssh-client-playground`. The ship plays several roles at once so that you can practise the client side on a single machine:

| Item | What it is |
| --- | --- |
| user `cadet` (password `cadetpass`) | you, the visitor. Do all the client work as this user with `sudo -iu cadet` |
| user `pilot` (password `pilotpass`) | the crew member on the "remote" station |
| `sshd` on port `2222` (`station`) | the remote station you connect to |
| `sshd` on port `2223` (`relay`) | a relay ship, used as a jump host |
| a web service on `127.0.0.1:8081` | a service that listens on loopback only, so you need a tunnel to reach it "from outside" |

The real `sshd` on port 22 carries your own session. Never change it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Keys, ssh-copy-id And Known Hosts](./course-01-keys-and-known-hosts.md): make a key pair, install the public half, and understand the host key check.
2. [The Client Configuration File](./course-02-the-client-configuration-file.md): nicknames, defaults, jump hosts and how to see what `ssh` really uses.
3. [Tunnels Through The Channel](./course-03-tunnels.md): local, remote and dynamic forwards.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

Almost every administrator task on a remote ship starts with `ssh`. The exam expects key-based login, a working `~/.ssh/config` and at least one tunnel, and it expects you to leave the account in a state that still works after a reboot.

<!-- curriculum-practice -->
## Practice and assessment

- [OpenSSH Client Lab](labs/lab-01/question.md): Create a key pair and install the public key for key login; Write a host alias in the client configuration file; Open a local port forward through an SSH server.
- [Application Proxy and SSH Capstone Lab](../capstone/labs/lab-01/question.md): Reverse-proxy every path on one port to a fixed backend path; Spread requests on another port across two backends with an upstream block; Keep the whole NGINX configuration valid and the existing apps untouched.
