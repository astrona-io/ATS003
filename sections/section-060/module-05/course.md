# Network Troubleshooting Workflow

Astronaut, when a signal does not arrive, the worst thing you can do is poke at random switches. A good flight engineer works through the same ladder every time, from the antenna up to the shields, and stops at the first rung that is broken. This module teaches that ladder and the tools for each rung: `ip`, `getent`, `ping`, `traceroute`, `mtr`, `ss`, `curl` and `tcpdump`.

## Learning objectives

After this module you can:

- Work through the troubleshooting ladder in order: link, address, route, name, port, firewall.
- Use `ip -br link`, `ip -br addr` and `ip route get` to find link, address and route faults.
- Tell the error messages apart: "Name or service not known", "Network is unreachable", "No route to host", "Connection refused" and a plain timeout.
- Follow a signal hop by hop with `ping`, `traceroute`, `tracepath` and `mtr`, and read loss and stars correctly.
- Prove whether a port answers with `ss`, `curl -v` and `tcpdump`.
- Fix a service that is unreachable because of a down link, a wrong name entry and a firewall rule.

## Before you start

A short pre-flight check: the knowledge this module expects, and what is waiting in your playground.

### What you should already know

- **The shell.** You can open a shell and use `sudo`.
- **Addresses and ports.** An IP address is a ship's call sign, and a port is a radio channel on its antenna.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine. Open a shell with `astrona ssh network-troubleshooting-playground`. It runs a small web service called `portal` and has three helper commands that break one rung of the ladder at a time, so you can practise finding each fault:

| Item | What it is |
| --- | --- |
| interface `lab0` | a practice antenna with `10.66.0.10/24` |
| `portal.service` | a web service on port `8443` on all addresses |
| name `portal.lab` | an entry in `/etc/hosts` for `10.66.0.10` |
| `sudo break-link`, `sudo break-name`, `sudo break-firewall` | break one rung on purpose |
| `sudo fix-all` | put everything back |

The management interface carries your own session. Never change it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [Work Up The Ladder](./course-01-work-up-the-ladder.md): the order of the checks and what each error message tells you.
2. [Follow The Path](./course-02-follow-the-path.md): `ping`, `traceroute`, `tracepath` and `mtr`.
3. [Prove The Port And Read The Wire](./course-03-prove-the-port-and-read-the-wire.md): `ss`, `curl -v`, `tcpdump` and the counters.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, a self-check and cleanup.

## Why this matters

The exam gives you a machine that "does not work" and a clock. Candidates who guess lose time. Candidates who climb the ladder find the fault in minutes, and they can say which layer it was in.

<!-- curriculum-practice -->
## Practice and assessment

- [Network troubleshooting capstone](labs/lab-01/question.md): Climb the ladder from link to firewall and find three faults; Repair the link, the name and the firewall rule in order; Prove the service answers end to end with curl.
