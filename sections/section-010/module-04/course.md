# Local Hostname Resolution

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
- `prod-app-01` is the primary hostname.
- `app-server` is an additional alias.

Both names resolve to the same address.

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

Changes to `/etc/hosts` normally take effect immediately. A system restart is usually not required.

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

However, `getent` is normally the better command for testing name resolution because `ping` also tests network reachability and ICMP responses.

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