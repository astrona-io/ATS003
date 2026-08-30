# Local Hostname Resolution

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-04/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-04/playground
> astrona destroy hostname-resolution-playground
> ```

A hostname gives a machine a human-readable identity; **name resolution** turns that name into an IP address an application can connect to. For example, resolution can turn `prod-app-01` into a loopback address such as `127.0.1.1`, or into an interface address such as `192.168.1.50`.

Linux can get that mapping from several sources: the local `/etc/hosts` file, a DNS server, multicast DNS, a service such as `systemd-resolved`, and others. When something on the machine needs the address for a name, it does not go straight to DNS. It asks a switchboard — the **Name Service Switch (NSS)** — which consults a configured list of sources in order and returns the first answer. `/etc/hosts` is usually first on that list. This module is about that local source and the switchboard in front of it.

## Learning objectives

After this module you can:

- Read an `/etc/hosts` line and identify the IP address, the canonical hostname, and any aliases.
- Explain why the NSS switchboard, not DNS directly, decides where a name lookup goes, and read the `hosts:` line in `/etc/nsswitch.conf` to see the order.
- Add or remove an `/etc/hosts` entry with `sudo` and confirm it resolves immediately with `getent hosts`.
- Explain why `getent` is a cleaner test of name resolution than `ping`.
- Choose between a loopback address such as `127.0.1.1` and an interface address for a hostname entry, based on how the name is used.
- Explain why an `/etc/hosts` entry resolves only on the machine that holds it, and when DNS is the right tool instead.

## Before you start

This module assumes you can open a shell, run commands with `sudo`, edit a text file, and have seen a dotted IPv4 address such as `192.168.1.50`. It assumes you know a machine has a static hostname set with `hostnamectl`, from the previous module. DNS, NSS, canonical hostname, and loopback are all defined as they come up.

Open a shell on the playground VM with `astrona ssh astro-hostname-resolution-playground`. It starts with a prepared `/etc/hosts`: the static hostname `prod-app-01` mapped to the loopback address `127.0.1.1` with alias `app-server`, plus a `db-primary` (alias `db`) line pointing at `192.168.50.10` where nothing is listening — it is there so you can watch a name resolve and still fail to connect. The playground network has no DNS server, so `files` is the only source that ever answers. Editing `/etc/hosts` here is safe and reversible.

## Key terms

| Term | Meaning in this module |
|---|---|
| **Name resolution** | Turning a name into an IP address (or the reverse). |
| **`/etc/hosts`** | A plain-text file of static `IP name [aliases]` mappings, local to one machine. |
| **Canonical hostname** | The first name after the IP on an `/etc/hosts` line; any further names on the line are aliases. |
| **Loopback address** | Any address in `127.0.0.0/8` (IPv4) or `::1` (IPv6); traffic to it never leaves the machine. |
| **NSS** | Name Service Switch — the mechanism that decides which sources to consult, and in what order, configured in `/etc/nsswitch.conf`. |
| **`getent`** | A tool that performs a lookup through NSS, exactly as a normal application would. |
| **DNS** | The network-wide name service; out of scope here except as a contrast. |

## `/etc/hosts`: static name-to-address mappings

`/etc/hosts` holds static mappings, one per line, in the form:

```text
IP_ADDRESS   CANONICAL_HOSTNAME   [ALIAS ...]
```

For example:

```text
192.168.1.50 prod-app-01 app-server
```

Here `192.168.1.50` is the address, `prod-app-01` is the **canonical hostname** (the primary name), and `app-server` is an alias. Both names resolve to the same address. Separate the fields with one or more spaces or tabs.

> [!TIP]
> **Try it — read the static table the playground starts with**
>
> ```sh
> cat /etc/hosts
> ```
>
> Expect something like:
>
> ```text
> 127.0.0.1 localhost
> ::1 localhost ip6-localhost ip6-loopback
> 127.0.1.1 prod-app-01 app-server
> 192.168.50.10 db-primary db
> ```
>
> The playground set the static hostname to `prod-app-01` and mapped it to the loopback address `127.0.1.1`, with `app-server` as an alias. The last line maps `db-primary` (alias `db`) to a non-loopback address — nothing is listening there; it exists so you can see a name resolve to an interface-style address. Exact contents vary by image.

## `getent`: look up a name the way an application does

Reading `/etc/hosts` with `cat` shows what is *in the file*. It does not tell you what the system would actually return for a name — that depends on NSS and every source it is configured to consult. `getent` — read it as *get entries* — queries an NSS database directly, following the same sources and order a normal program would:

```bash
getent hosts prod-app-01
```

`hosts` is the database name. `getent` has others (`passwd`, `group`, …); `hosts` is the one for name resolution. Two more specific forms return address records only:

```bash
getent ahostsv4 prod-app-01     # IPv4 answers
getent ahostsv6 prod-app-01     # IPv6 answers
```

`getent` reads state and changes nothing.

> [!TIP]
> **Try it — resolve the seeded names through NSS**
>
> ```sh
> getent hosts prod-app-01
> getent hosts app-server
> getent hosts db-primary
> ```
>
> Expect something like:
>
> ```text
> 127.0.1.1       prod-app-01 app-server
> 127.0.1.1       prod-app-01 app-server
> 192.168.50.10   db-primary db
> ```
>
> The canonical name and its alias resolve to the same address — `getent` returns the whole matching line either way. `db-primary` resolves to its interface-style address. Every one of these answers came from `/etc/hosts`, because that is the only source with anything to say on this network.

## Name-resolution order: `/etc/nsswitch.conf`

NSS decides which sources to consult and in what order. The configuration is `/etc/nsswitch.conf`; the line that matters here is `hosts:`.

```bash
grep '^hosts:' /etc/nsswitch.conf
```

A minimal line reads:

```text
hosts: files dns
```

`files` means local files such as `/etc/hosts`; `dns` means the configured DNS service. Sources are consulted **left to right**, first answer wins — so `files` before `dns` means `/etc/hosts` is checked before DNS, and an entry there overrides whatever DNS would say for the same name. A current system often lists more:

```text
hosts: files mdns4_minimal resolve dns
```

- `files` — `/etc/hosts`;
- `resolve` — `systemd-resolved`;
- `mdns4_minimal` / `mdns` — multicast DNS, for `*.local` names;
- `myhostname` — the machine's own hostname, via an NSS module.

Do not change this line without understanding the machine's resolution setup; a wrong order can stop local *and* network names from resolving.

> [!TIP]
> **Try it — see which sources this machine consults, and in what order**
>
> ```sh
> grep '^hosts:' /etc/nsswitch.conf
> ```
>
> Expect something like:
>
> ```text
> hosts: files ... dns
> ```
>
> `files` sits before `dns`, so every lookup checks `/etc/hosts` first and only falls through to DNS on a miss. That ordering is why the entries from `cat /etc/hosts` win over anything a DNS server might say. In this playground there is no DNS server, so the `dns` step never returns anything — `files` is the whole story here.

## Choosing the address for an entry

You do not always need an `/etc/hosts` entry for a hostname — it may already be covered by DNS, a DHCP/DNS integration, or another service. But adding the machine's own name locally guarantees it resolves even when DNS is down. Without a local entry, some tools warn:

```text
sudo: unable to resolve host prod-app-01: Name or service not known
```

When you do add an entry, the address depends on how the name is used:

- **A loopback address** such as `127.0.1.1` (common on Debian-based systems) when the name only needs to identify the *local* machine. Traffic to `127.0.0.0/8` never leaves the box.
- **An interface address** such as `192.168.1.50` when the name should stand for a particular network connection.
- **DNS**, not `/etc/hosts`, when *other* machines must resolve the name reliably.

Leave the standard localhost lines alone:

```text
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
```

They are how local IPv4 and IPv6 traffic finds `localhost`.

## Updating `/etc/hosts`

`/etc/hosts` needs administrative privileges to change — edit it with `sudo nano /etc/hosts`, or append a line with `sudo tee -a`. Changes take effect immediately; no restart. A caching layer such as `systemd-resolved` or `nscd`, if present, can briefly hold an old answer.

> [!TIP]
> **Try it — add an entry and watch it resolve straight away**
>
> This appends one line to a system file, so it needs `sudo`. Undo it by editing the line back out.
>
> ```sh
> echo '10.0.0.9 test-node' | sudo tee -a /etc/hosts
> getent hosts test-node
> ```
>
> Expect:
>
> ```text
> 10.0.0.9        test-node
> ```
>
> No service was restarted — the mapping is live the moment the file is saved. Remove it again with `sudo nano /etc/hosts` (delete the line).

## Resolution is not reachability

A name resolving tells you the mapping exists. It does not tell you the host behind the address answers. `getent` tests resolution only. `ping` resolves the name *and* then tries to reach the address, so a `ping` failure could be either problem — which is why `getent` is the cleaner test of resolution alone.

> [!TIP]
> **Try it — a name that resolves but does not connect**
>
> ```sh
> getent hosts db-primary
> ping -c 1 db-primary
> ```
>
> Expect something like:
>
> ```text
> 192.168.50.10   db-primary
> ```
>
> ```text
> PING db-primary (192.168.50.10) 56(84) bytes of data.
> --- db-primary ping statistics ---
> 1 packets transmitted, 0 received, 100% packet loss
> ```
>
> `getent` returns the mapping instantly from `/etc/hosts`. `ping` resolves the same name — note it prints the address — then fails, because nothing is listening at `192.168.50.10`. Name resolution succeeded; connectivity did not.

## Local resolution compared with DNS

An `/etc/hosts` entry only affects the machine that holds the file. Adding `192.168.1.50 prod-app-01` lets *this* machine resolve `prod-app-01`; it does nothing for any other machine. For a name that many machines must resolve, register it in DNS instead.

`/etc/hosts` is the right tool for:

- local machine identity;
- small or isolated environments;
- temporary overrides;
- systems that must work without DNS;
- troubleshooting name-resolution problems.

> [!WARNING]
> **Common pitfalls**
>
> - **Expecting an `/etc/hosts` entry to work network-wide.** It resolves only on the machine that holds the file. Other machines need the name in DNS.
> - **Editing or removing the `127.0.0.1 localhost` / `::1 localhost` lines.** Many programs assume `localhost` resolves locally; breaking those lines breaks them. Add your entries on new lines, leave these alone.
> - **Testing resolution with `ping`.** `ping` also checks reachability, so a failure is ambiguous. Use `getent hosts <name>` to test resolution by itself.
> - **Reading `/etc/hosts` with `cat` and calling it verified.** The file is one source; NSS may consult others first. `getent` shows what the system actually returns.
> - **Pinning a public name in `/etc/hosts` as a quick fix.** It overrides DNS for that name on this host and then goes stale silently when the real address changes. Use it as a deliberate temporary override, not a permanent record.
