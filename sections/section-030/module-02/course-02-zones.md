# Zones

Astronaut, the **zone** is the central object in firewalld. Everything you allow, you allow *in a zone*, and every packet is handled *by a zone*. A zone is a shield preset for a group of antennas.

This part covers what a zone contains, the built-in zones and how open each one is, and the part people get wrong: the exact order that decides which zone a packet lands in.

## A zone is a named policy

A zone bundles everything the shields need to know about one trust level. This section lists its contents and shows you a real zone on your playground.

### What a zone contains

A zone bundles:

- a **target**: what happens to a packet that matches no rule in the zone;
- a list of allowed **services**;
- a list of allowed **ports** and **protocols**;
- optional **rich rules**, **port forwards**, **masquerade** and ICMP filters (ICMP is the protocol for short status messages such as ping);
- the **interfaces** and **source addresses** bound to it.

Picture each zone as a shield preset with its own list of signals it lets through. `public` is the preset for antennas facing open space: a short list, everything else turned away. `trusted` is the preset for antennas linked only to your own fleet: no list, everything gets in. Which preset handles a signal depends on where it came from, not on what it says.

### Read the public zone's policy

`firewall-cmd --zone=<name> --list-all` prints one zone's whole policy. With no `--zone` it shows the **default** zone.

<!-- astrona:playground:renew -->

```sh
sudo firewall-cmd --zone=public --list-all
```

You see something like this:

```text
public (active)
  target: default
  interfaces: enp0s1 enp0s2
  services: dhcpv6-client ssh
  ports:
  ...
```

`services: … ssh` is why your SSH (Secure Shell, the sealed communications channel between ships) session survived firewalld starting: port 22 is allowed in the zone your management interface sits in. The `ports:` line is empty because nothing has opened a raw port yet.

## The target: what "no match" does

The target is the zone's answer to every packet that no rule allowed. There are four:

| Target | Packet that matched nothing |
|---|---|
| `default` | rejected with an ICMP error (the usual case; it behaves like `%%REJECT%%` for incoming traffic, but also allows ICMP and lets forwarded and outgoing traffic behave differently) |
| `%%REJECT%%` | rejected with an ICMP error, so the sender fails fast |
| `DROP` | dropped silently, so the sender waits for a timeout and the host looks dark |
| `ACCEPT` | accepted, so the zone becomes a list of things to *deny* rather than allow |

The `drop` and `block` zones get their behaviour from their target, and `trusted` has the target `ACCEPT`.

## The built-in zones

firewalld ships a ready-made set of zones, from fully closed to fully open. The table runs from the least open to the most open.

### From closed to open

| Zone | Target | Typical use |
|---|---|---|
| `drop` | `DROP` | incoming traffic denied and **silent**; outgoing still works. Hostile networks. |
| `block` | `%%REJECT%%` | incoming traffic denied **with an ICMP reject**; outgoing still works. |
| `public` | `default` | **the stock default.** An untrusted network; only services you allow (SSH, DHCPv6 client) get in. |
| `external` | `default` | like `public`, but with **masquerade on**, for the outward-facing interface of a gateway. |
| `dmz` | `default` | for hosts in a demilitarised zone (DMZ), a buffer network between the outside and your own: limited incoming traffic, no masquerade. |
| `work` | `default` | a mostly trusted network; a few more services allowed. |
| `home` | `default` | like `work`, a little more open (allows `mdns`, `samba-client` and others). |
| `internal` | `default` | a trusted internal network; the most open of the zones with the `default` target. |
| `trusted` | `ACCEPT` | **everything allowed.** Use it only where you fully control the network. |

DHCPv6 is the way an IPv6 host can ask the harbour master for a call sign; masquerade is the relay station swapping every outgoing call sign for its own.

### Your own zones

You can also create your own zone: `firewall-cmd --permanent --new-zone=bastion`, then `--reload`.

## How a packet's zone is chosen

This is the exam point. For an incoming packet, firewalld picks **exactly one** zone. It checks three things in order and stops at the first match.

### The three levels

1. **Source binding.** Is the packet's source address (or range) bound to a zone (`--add-source=`)? If yes, that zone. Source bindings win over everything.
2. **Interface binding.** Is the packet's *incoming interface* bound to a zone (`--change-interface=` or `--add-interface=`)? If yes, that zone.
3. **The default zone.** Everything not matched above.

So an interface you never assigned is handled by the **default zone**, not by whatever zone you happened to be editing. And a source binding overrides the interface: bind `10.0.0.0/8` to `internal`, and traffic from that range is `internal` *even if it arrives on an interface bound to `public`*.

### The query commands

These commands show what each level says:

- `firewall-cmd --get-default-zone` shows level 3.
- `firewall-cmd --get-zone-of-interface=<dev>` shows what level 2 says for one interface.
- `firewall-cmd --get-zone-of-source=<addr>` shows what level 1 says for one source.
- `firewall-cmd --get-active-zones` lists every zone that has an interface **or** a source bound right now, and what is bound to it.

### Where firewalld stands right now

```sh
sudo firewall-cmd --state
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones
```

You see something like this:

```text
running
public
public
  interfaces: enp0s1 enp0s2
```

The daemon is `running`, the default zone is `public`, and both interfaces are in `public`. Neither was assigned anywhere else, so both fall through to the default zone (level 3). Your interface names may differ.

## Move an interface, and bind a source

`firewall-cmd --zone=<name> --change-interface=<dev>` moves an interface into a zone, and out of the zone it was in. Different zones allow different things, so the move changes what that interface's traffic can reach.

### Move the spare interface into another zone

Use the name of the `192.168.90.10` interface from `ip -brief -4 addr show`; the examples call it `enp0s2`. **Never** run this against the management interface: moving it to a zone without `ssh` cuts your session.

```sh
sudo firewall-cmd --zone=internal --change-interface=enp0s2
sudo firewall-cmd --get-active-zones
```

The interface has moved:

```text
internal
  interfaces: enp0s2
public
  interfaces: enp0s1
```

`enp0s2` is now handled by the `internal` policy, and `enp0s1` (your SSH interface) stays in `public`. A packet arriving for `192.168.90.10` is now checked against `internal`.

### A source binding beats the interface

With `enp0s2` still in `internal`, bind its address to the `drop` zone by source, and watch source precedence win:

```sh
sudo firewall-cmd --zone=drop --add-source=192.168.90.10
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-zone-of-source=192.168.90.10
```

Look for `192.168.90.10` listed under `drop`, even though its interface is bound to `internal`. A packet from that address is now handled by `drop`: level 1 beats level 2.

Undo both changes:

```sh
sudo firewall-cmd --zone=drop --remove-source=192.168.90.10
sudo firewall-cmd --zone=public --change-interface=enp0s2
```

## Common pitfalls

> [!WARNING]
> - **Expecting a zone to apply everywhere.** A zone only governs traffic whose source or incoming interface is bound to it. An interface you never assigned is in the *default* zone.
> - **Forgetting that a source binding wins.** A source bound to `drop` is dropped, even on an interface in `trusted`.
> - **Moving the management interface.** Moving it into a zone without `ssh` cuts your session. Practise on the spare interface only.

> *Every packet is handled by exactly one zone, chosen by source binding first, then interface binding, then the default zone. An interface you never assigned is in the default zone, not the one you were editing.*
