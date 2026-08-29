# Netplan YAML Configurations

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-060/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-02/playground
> astrona destroy netplan-yaml-playground
> ```

**Netplan** is Ubuntu's way of describing network configuration. You write
**YAML** files under `/etc/netplan/`; the `netplan` command reads them all,
merges them, and **renders** the low-level configuration for a **backend
renderer** — `systemd-networkd` (the default on Ubuntu Server) or
`NetworkManager` (the default on Ubuntu Desktop, and the subject of the previous
module). You do not edit the renderer's files directly; netplan generates them.

The style is **declarative**: the YAML states the desired end result — this
interface has this address, this route, these DNS servers — and netplan makes
the system match. That is the opposite of `ip` or `nmcli`, where you issue one
step at a time.

A minimal file looks like this:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
```

`network:` and `version: 2` are always the top. Under a device category
(`ethernets`, `bonds`, `bridges`, `vlans`, `wifis`, …) each interface is a key
with its settings nested beneath.

## Learning objectives

After this module you can:

- Explain that netplan is a declarative front end that renders YAML under
  `/etc/netplan/` to `systemd-networkd` or `NetworkManager`.
- Write a `network:` block for a static interface — `addresses`, `routes`,
  `nameservers` — with space-only indentation.
- Merge and inspect the effective configuration with `netplan get`.
- Render the backend files with `netplan generate` and read what netplan
  produced.
- Apply a change safely with `netplan try` (auto-rollback) and permanently with
  `netplan apply`.
- Predict how multiple files in `/etc/netplan/` merge, and why file order
  matters.

## Before you start

This module follows the NetworkManager module — netplan is the Ubuntu
alternative, and can even use NetworkManager as its renderer. Interface names,
CIDR notation, default gateway, and DNS resolvers are used as covered in the
section-010 material. You need a shell, `sudo`, and a text editor; YAML is
introduced here.

The playground is a single VM (`astrona ssh netplan-yaml-playground`) where
netplan is native (renderer `systemd-networkd`). One **spare NIC** sits on the
isolated `192.168.130.0/24` segment — no DHCP, no router, so static addressing
is the realistic case — and has **no netplan file yet**. Its name is in
`/root/lab-spare-iface` (or `ip -br link`). The **management interface** has its
own cloud-init netplan file; **leave that file alone**. `netplan try`'s
120-second auto-revert is a safety net, and the spare NIC is not your SSH path
anyway. `sudo` needs no password.

## Reading the merged configuration

`/etc/netplan/` can hold several files. `netplan get` parses them all, merges
them, and prints the combined result — which is also a quick way to confirm the
YAML is valid.

> [!TIP]
> **Try it — what netplan sees right now**
>
> ```sh
> sudo netplan get
> ```
>
> Expect the management interface's cloud-init config and nothing for the spare:
>
> ```text
> network:
>   version: 2
>   ethernets:
>     enp1s0:
>       dhcp4: true
> ```
>
> Only `enp1s0` (the SSH interface) is configured, by
> `/etc/netplan/50-cloud-init.yaml`. The spare NIC is absent — netplan is not
> managing it because no file mentions it.

## Writing an interface block

A static interface needs `dhcp4: false`, an `addresses` list (each entry
**with** its prefix), and usually `routes` and `nameservers`. Indentation is
**spaces only** — YAML forbids tab characters for indentation, and every nesting
level is two more spaces than its parent.

Create `/etc/netplan/90-lab.yaml` (a high number so it merges last), owned by
root and mode `600`:

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      dhcp4: false
      addresses:
        - 192.168.130.50/24
      nameservers:
        addresses: [192.168.130.1]
```

> [!TIP]
> **Try it — add the spare NIC and check it merged**
>
> Use your spare interface name in place of `enp2s0`, then:
>
> ```sh
> sudo chmod 600 /etc/netplan/90-lab.yaml
> sudo netplan get ethernets.enp2s0
> ```
>
> Expect just that interface's merged settings:
>
> ```text
> addresses:
> - 192.168.130.50/24
> dhcp4: false
> nameservers:
>   addresses:
>   - 192.168.130.1
> ```
>
> `netplan get` accepted the file and now reports the spare NIC alongside the
> management one. Nothing has been applied yet — this is still just the desired
> state on paper.

## YAML indentation: spaces, never tabs

The single most common netplan error is a stray tab or a wrong indent level.
YAML uses whitespace to express structure, and a tab where spaces are expected
is a hard parse error.

> [!TIP]
> **Try it — see the parser reject a tab**
>
> Add a line indented with a literal tab (for example a tab before
> `dhcp4: false`), then:
>
> ```sh
> sudo netplan get
> ```
>
> Expect a parse error naming the file and line:
>
> ```text
> Error in network definition /etc/netplan/90-lab.yaml line 5 column 0: found character '\t' that cannot start any token
> ```
>
> netplan will not render anything while a file is unparseable. Replace the tab
> with spaces and `netplan get` succeeds again. Keep the editor set to insert
> spaces for indentation.

## Rendering without applying: `netplan generate`

netplan is a translator. `netplan generate` writes the backend's real
configuration files — for `systemd-networkd`, under `/run/systemd/network/` —
without touching the running network. It is how you see exactly what your YAML
turns into.

> [!TIP]
> **Try it — read the file netplan produced**
>
> ```sh
> sudo netplan generate
> cat /run/systemd/network/10-netplan-enp2s0.network
> ```
>
> Expect a `systemd-networkd` file built from your YAML:
>
> ```text
> [Match]
> Name=enp2s0
>
> [Network]
> DHCP=no
> Address=192.168.130.50/24
> DNS=192.168.130.1
> ```
>
> Your five lines of YAML became a `networkd` unit. If you were using
> `renderer: NetworkManager`, the same command would write an `.nmconnection`
> keyfile instead — the format from the previous module.

## Applying safely: `netplan try`

`netplan apply` renders the config and tells the backend to adopt it — live.
On a remote machine a mistake in that config (a wrong address, a broken default
route) can cut your connection with nothing to undo it.

`netplan try` is the safe form: it applies the config, then starts a
**120-second countdown**. Press Enter to keep the change; do nothing and it
**reverts** to the previous configuration automatically. Always use it for
changes to an interface you depend on.

> [!TIP]
> **Try it — apply with the safety timer**
>
> ```sh
> sudo netplan try
> ```
>
> Expect the config to apply and a prompt to appear:
>
> ```text
> Warning: Stopping systemd-networkd.service, but it can still be activated by:
>   systemd-networkd.socket
> Do you want to keep these settings?
>
> Press ENTER before the timeout to accept the new configuration
>
> Changes will revert in 120 seconds
> ```
>
> Press Enter to keep it, then check the interface:
>
> ```sh
> ip -brief addr show enp2s0
> networkctl status enp2s0
> ```
>
> ```text
> enp2s0   UP   192.168.130.50/24
> ```
>
> The address is live and on disk. `sudo netplan apply` does the same thing
> **without** the timer — fine on the console or for an interface you are not
> connected through, risky otherwise.

## How multiple files merge

netplan reads every `*.yaml` in `/etc/netplan/` in filename order and merges
them **key by key**. When two files set the same leaf key, the one that sorts
**later** wins — which is why cloud-init uses `50-` and you use higher numbers to
override it. It is not whole-file replacement: a `99-` file setting only
`addresses` for an interface leaves that interface's `routes` from a `50-` file
intact.

> [!TIP]
> **Try it — a later file overrides one key**
>
> Create `/etc/netplan/99-override.yaml` (mode `600`) changing just the address:
>
> ```yaml
> network:
>   version: 2
>   ethernets:
>     enp2s0:
>       addresses:
>         - 192.168.130.60/24
> ```
>
> ```sh
> sudo chmod 600 /etc/netplan/99-override.yaml
> sudo netplan get ethernets.enp2s0
> ```
>
> Expect the address from `99-` and the `nameservers` still from `90-`:
>
> ```text
> addresses:
> - 192.168.130.60/24
> dhcp4: false
> nameservers:
>   addresses:
>   - 192.168.130.1
> ```
>
> `99-override.yaml` won for `addresses` only; everything it did not mention
> came through from `90-lab.yaml`. Delete the override file when you are done so
> the picture stays simple.

## Where this fits

Netplan, NetworkManager keyfiles, raw `systemd-networkd` `.network` files, and
the old `ifupdown` `/etc/network/interfaces` are all **persistent layers** over
the addressing, routing, and DNS concepts from section-010 — different front
ends, same end result on the wire. On Ubuntu, netplan is the one in charge:
setting `renderer: NetworkManager` makes `nmcli` show the profiles netplan
generated, so the two modules meet. Cloud images configure the primary NIC
through `50-cloud-init.yaml`; a production host typically adds its own
higher-numbered file, or replaces cloud-init's networking and disables it.

> [!WARNING]
> **Common pitfalls**
>
> - **Tabs or a wrong indent level.** YAML structure is whitespace. A tab is a
>   parse error; two spaces too few or too many changes what a key belongs to.
>   `netplan get` is the fast check.
> - **`netplan apply` on a remote box.** No auto-revert. Use `netplan try` for
>   anything touching the interface you are connected through.
> - **File-order surprises.** `50-cloud-init.yaml` can override a lower-numbered
>   file you wrote. Use a higher number and confirm with `netplan get`.
> - **An address without its prefix.** `addresses: [192.168.1.10]` is invalid —
>   it must be `192.168.1.10/24`.
> - **`gateway4:` in an example.** It is deprecated. Use
>   `routes: [{to: default, via: <ip>}]`.
> - **Editing the rendered files.** Anything under `/run/systemd/network/` is
>   regenerated on the next `netplan generate`. Edit the YAML in `/etc/netplan/`.
> - **World-readable netplan files.** They can hold secrets (Wi-Fi keys);
>   recent netplan warns unless they are `chmod 600`.
> - **`dhcp4: true` with no DHCP server.** The interface sits in `configuring`
>   and never gets an address.
