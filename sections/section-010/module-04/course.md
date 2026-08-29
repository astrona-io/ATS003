# Local Hostname Resolution

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-010/module-04/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-04/playground
> astrona destroy hostname-resolution-playground
> ```

A hostname gives a Linux machine a human-readable identity. Name resolution translates that hostname into an IP address that applications can use.

For example, name resolution can translate:

```text
prod-app-01
```

into:

```text
127.0.1.1
```

or an address assigned to a network interface:

```text
192.168.1.50
```

Linux can obtain this mapping from several sources, including:

- The local `/etc/hosts` file.
- A DNS server.
- Multicast DNS (mDNS).
- A system service such as `systemd-resolved`.
- Other name services configured on the machine.

A useful mental model: when something on the machine needs the address for a name, it does not go straight to DNS. It asks a switchboard — the **Name Service Switch (NSS)** — which consults a configured list of sources in order and returns the first answer. `/etc/hosts` is usually the first source on that list. This chapter is about that local source and the switchboard in front of it.

## Key terms

| Term | Meaning in this chapter |
|---|---|
| **Hostname** | The machine's human-readable name, such as `prod-app-01`. The *static* hostname is stored on disk and set with `hostnamectl`. |
| **Name resolution** | Turning a name into an IP address (or the reverse). |
| **`/etc/hosts`** | A plain-text file of static `IP name [aliases]` mappings, local to one machine. |
| **Canonical hostname** | The first name after the IP on an `/etc/hosts` line; any further names on the line are aliases. |
| **Loopback address** | Any address in `127.0.0.0/8` (IPv4) or `::1` (IPv6); traffic to it never leaves the machine. |
| **NSS** | Name Service Switch — the mechanism that decides which sources to consult, and in what order, configured in `/etc/nsswitch.conf`. |
| **`getent`** | A tool that performs a lookup through NSS, exactly as a normal application would. |
| **DNS** | The network-wide name service; out of scope here except as a contrast. |

## Hostnames and `/etc/hosts`

The `/etc/hosts` file contains static mappings between IP addresses and hostnames.

Display its current contents:

```bash
cat /etc/hosts
```

A simple file might look like this:

```text
127.0.0.1 localhost
127.0.1.1 prod-app-01
```

Each entry starts with an IP address followed by one or more names:

```text
IP_ADDRESS CANONICAL_HOSTNAME OPTIONAL_ALIASES
```

For example:

```text
192.168.1.50 prod-app-01 app-server
```

In this entry:

- `192.168.1.50` is the IP address.
- `prod-app-01` is the primary (canonical) hostname.
- `app-server` is an additional alias.

Both names resolve to the same address.

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

## Should every hostname be added to `/etc/hosts`?

Changing the static hostname does not always require an `/etc/hosts` entry.

The hostname might already be resolved by:

- A local DNS server.
- A DNS record managed by the network.
- A DHCP and DNS integration.
- Another name-resolution service.

However, adding the machine's hostname to `/etc/hosts` can ensure that it resolves locally even when DNS is unavailable.

If the local hostname cannot be resolved, some applications might display warnings similar to:

```text
sudo: unable to resolve host prod-app-01: Name or service not known
```

The exact behaviour depends on the Linux distribution and application configuration.

## Choosing the correct address

Some Debian-based distributions commonly map the machine's hostname to `127.0.1.1`:

```text
127.0.1.1 prod-app-01
```

The `127.0.0.0/8` range is reserved for loopback traffic. Connections to these addresses remain inside the local machine and are not sent to the physical network.

Other distributions may map the hostname to an address assigned to a network interface:

```text
192.168.1.50 prod-app-01
```

The correct choice depends on how the hostname should be used:

- Use a loopback address when the name only needs to identify the local machine.
- Use an interface address when the name should represent a particular network connection.
- Use DNS when other machines must reliably resolve the hostname.

Do not replace or remove the standard localhost entries:

```text
127.0.0.1 localhost
::1 localhost
```

These entries are used for local IPv4 and IPv6 communication.

## Updating `/etc/hosts`

The `/etc/hosts` file requires administrative privileges to modify.

Open it in a text editor:

```bash
sudo nano /etc/hosts
```

A Debian-style configuration for a machine named `prod-app-01` might look like this:

```text
127.0.0.1 localhost
127.0.1.1 prod-app-01
::1       localhost ip6-localhost ip6-loopback
```

Separate the address and hostname using one or more spaces or tabs.

Changes to `/etc/hosts` normally take effect immediately. A system restart is usually not required. Some setups run a caching layer (for example `systemd-resolved` or `nscd`) that can briefly hold an old answer.

> [!TIP]
> **Try it — add an entry and watch it resolve straight away**
>
> This appends one line to a system file, so it needs `sudo`. It is safe to undo by editing the line back out.
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
> No service was restarted — the mapping is live the moment the file is saved. Remove it again with `sudo nano /etc/hosts` (delete the line). As an aside: if you set the static hostname to a name that has *no* `/etc/hosts` entry, `sudo` itself starts printing `unable to resolve host <name>` until you add one.

## Verifying local name resolution

Use `getent` to test name resolution through the system's configured name-service mechanism:

```bash
getent hosts prod-app-01
```

Example response:

```text
127.0.1.1       prod-app-01
```

Unlike reading `/etc/hosts` directly, `getent` uses the name-resolution sources and priority configured for the system.

You can also query the IPv4 host database:

```bash
getent ahostsv4 prod-app-01
```

If IPv6 is configured, query the IPv6 host database:

```bash
getent ahostsv6 prod-app-01
```

The `ping` command can provide an additional connectivity check:

```bash
ping -c 3 prod-app-01
```

However, `getent` is normally the better command for testing name resolution because `ping` also tests network reachability and ICMP responses. A name can resolve perfectly while the host it points at is unreachable.

> [!TIP]
> **Try it — resolution is not the same as reachability**
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
> `getent` returns the mapping instantly from `/etc/hosts`. `ping` resolves the same name — notice it prints the address — then fails, because nothing is listening at `192.168.50.10`. Name resolution succeeded; connectivity did not. That is why `getent` is the cleaner test of resolution alone.

## Name-resolution order

Linux uses the Name Service Switch (NSS) configuration to determine where it should search for information such as hostnames, users, and groups.

The configuration is stored in:

```text
/etc/nsswitch.conf
```

Display the hostname lookup configuration:

```bash
grep '^hosts:' /etc/nsswitch.conf
```

Example:

```text
hosts: files dns
```

In this example:

- `files` tells Linux to search local files such as `/etc/hosts`.
- `dns` tells Linux to query the configured DNS service.

The sources are generally checked from left to right. With `files` before `dns`, Linux checks `/etc/hosts` before querying DNS.

A modern system may contain additional sources:

```text
hosts: files mdns4_minimal resolve dns
```

Possible sources include:

- `files`: Local entries in `/etc/hosts`.
- `dns`: Traditional DNS queries.
- `resolve`: Name resolution through `systemd-resolved`.
- `mdns` or `mdns4_minimal`: Multicast DNS used for names such as `host.local`.
- `myhostname`: Local hostname resolution provided by an NSS module.

The exact configuration depends on the Linux distribution and installed services.

Avoid changing `/etc/nsswitch.conf` unless you understand how the system performs name resolution. An incorrect configuration can prevent local and network hostnames from resolving.

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
> `files` sits before `dns`, so every lookup checks `/etc/hosts` first and only falls through to DNS on a miss. That ordering is why the entries you saw in `cat /etc/hosts` win over anything a DNS server might say for the same name. In this playground there is no DNS server on the network, so the `dns` step never returns anything — `files` is the whole story here.

## Local resolution compared with DNS

An `/etc/hosts` entry only affects the machine on which the file is configured.

For example, adding this entry:

```text
192.168.1.50 prod-app-01
```

allows the local machine to resolve `prod-app-01`. It does not automatically make the name available to other machines.

For network-wide name resolution, the hostname should normally be registered in a DNS service.

The `/etc/hosts` file is most useful for:

- Local machine identity.
- Small or isolated environments.
- Temporary overrides.
- Systems that must operate without DNS.
- Troubleshooting name-resolution problems.
