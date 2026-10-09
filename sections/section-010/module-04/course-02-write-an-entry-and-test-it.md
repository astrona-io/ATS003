# Write An Entry And Test It

Astronaut, now you write in the pocket address book yourself. Which address you put next to a name matters, and so does how you test the result.

This part shows you how to choose the address for an entry, how to add one, why a name that resolves can still be unreachable, and when the galaxy-wide directory (DNS) is the better tool.

## Choosing the address for an entry

You do not always need an `/etc/hosts` entry for a hostname. DNS, a DHCP and DNS setup, or another service may already cover it. But adding the machine's own name locally makes sure it resolves even when DNS is down.

### What happens without an entry

Without a local entry, some tools warn:

```text
sudo: unable to resolve host prod-app-01: Name or service not known
```

### Loopback, interface address or DNS

When you do add an entry, the address depends on how the name is used:

- **A loopback address** such as `127.0.1.1` (common on Debian-based systems such as Ubuntu) when the name only needs to identify the *local* machine. Traffic to `127.0.0.0/8` never leaves the machine.
- **An interface address** such as `192.168.1.50` when the name should stand for one particular network connection.
- **DNS**, not `/etc/hosts`, when *other* machines must resolve the name reliably.

Leave the standard localhost lines alone:

```text
127.0.0.1 localhost
::1       localhost ip6-localhost ip6-loopback
```

They are how local IPv4 and IPv6 traffic finds `localhost`.

## Updating `/etc/hosts`

`/etc/hosts` needs `sudo` (the captain's authority) to change. Edit it with `sudo nano /etc/hosts`, or add a line at the end with `sudo tee -a`.

### When the change takes effect

Changes take effect at once, with no restart. A caching layer such as `systemd-resolved` or `nscd`, if one is running, can hold an old answer for a short time.

### Add an entry and watch it resolve straight away

<!-- astrona:playground:renew -->

This adds one line to a system file, so it needs `sudo`. You undo it by editing the line out again.

```sh
echo '10.0.0.9 test-node' | sudo tee -a /etc/hosts
getent hosts test-node
```

The lookup prints:

```text
10.0.0.9        test-node
```

No service was restarted: the mapping is live the moment the file is saved. Remove it again with `sudo nano /etc/hosts` and delete the line.

## Resolution is not reachability

A name that resolves tells you the mapping exists. It does not tell you that the host behind the address answers. Keeping those two questions apart saves a lot of debugging time.

### Why `getent` is the cleaner test

`getent` tests resolution only. `ping` resolves the name *and* then tries to reach the address. So a `ping` failure could be either problem, while `getent` answers the resolution question on its own.

### A name that resolves but does not connect

Look up `db-primary`, then try to reach it:

```sh
getent hosts db-primary
ping -c 1 db-primary
```

The recorded output of `getent`:

```text
192.168.50.10   db-primary
```

And of `ping`:

```text
PING db-primary (192.168.50.10) 56(84) bytes of data.
--- db-primary ping statistics ---
1 packets transmitted, 0 received, 100% packet loss
```

`getent` returns the mapping at once from `/etc/hosts`. `ping` resolves the same name (it prints the address), then fails, because nothing is listening at `192.168.50.10`. Name resolution worked; connectivity did not.

> [!TIP]
> When a connection by name fails, run `getent hosts <name>` first. If it returns the right address, stop looking at names and start looking at the network.

## Local resolution compared with DNS

An `/etc/hosts` entry only affects the machine that holds the file. Adding `192.168.1.50 prod-app-01` lets *this* machine resolve `prod-app-01`; it does nothing for any other machine. For a name that many machines must resolve, register it in DNS instead.

### When `/etc/hosts` is the right tool

`/etc/hosts` is the right tool for:

- the local machine's own identity;
- small or isolated environments;
- temporary overrides;
- systems that must work without DNS;
- troubleshooting name resolution problems.

## Common pitfalls

> [!WARNING]
> - **Expecting an `/etc/hosts` entry to work across the network.** It resolves only on the machine that holds the file. Other machines need the name in DNS.
> - **Editing or removing the `127.0.0.1 localhost` and `::1 localhost` lines.** Many programs expect `localhost` to resolve locally. Add your entries on new lines and leave these alone.
> - **Testing resolution with `ping`.** `ping` also checks reachability, so a failure does not tell you which part failed. Use `getent hosts <name>` to test resolution on its own.
> - **Pinning a public name in `/etc/hosts` as a quick fix.** It overrides DNS for that name on this machine, and then goes out of date without warning when the real address changes. Use it only as a deliberate, temporary override.

## Your mission: Local Hostname Name Resolution Lab

You can now write an `/etc/hosts` entry and prove it resolves in both directions with `getent`. The mission asks you to add a second IPv4 address and an IPv6 address to the main interface, make them survive a reboot, and give the new address the name `app-srv1` in `/etc/hosts`, so that the name and the address resolve both ways.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop hostname-resolution-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-014
astrona start hostname-resolution-playground
```
