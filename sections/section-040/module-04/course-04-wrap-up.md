# Summary

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the directory clerk on board: who the clerk asks and in which order.

**From [Who Answers A Name](./course-01-who-answers-a-name.md):**

- `/etc/nsswitch.conf` sets the order. `hosts: files dns` means `/etc/hosts` first, then DNS.
- `getent hosts` asks the way applications do. `dig` asks a DNS server directly and ignores `/etc/hosts`.

**From [The Stub Resolver](./course-02-the-stub-resolver.md):**

- On Ubuntu 24.04 `/etc/resolv.conf` points to the stub at `127.0.0.53`. `systemd-resolved` answers from its cache or asks the real servers.
- `resolvectl status` shows servers and domains, `resolvectl query` tests a name, and `resolvectl flush-caches` clears the cache.

**From [Servers And Search Domains](./course-03-servers-and-search-domains.md):**

- Put `DNS=` and `Domains=` into a drop-in in `/etc/systemd/resolved.conf.d/`, then restart `systemd-resolved`.
- Netplan `nameservers:` sets servers and search domains for one interface.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [DNS Client Resolution Lab](./labs/lab-01/README.md) | Servers And Search Domains | point the resolver at a server, add a search domain and pin one name in `/etc/hosts` |

If you skipped it, go back to it now. It is short, and name resolution is on every exam.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A name works with <code>dig</code> but not with <code>ping</code>. Which tool shows what <code>ping</code> sees?</summary>

`getent hosts <name>`. It follows `nsswitch.conf` like `ping` does.
</details>

<details>
<summary>2. What does <code>nameserver 127.0.0.53</code> in <code>/etc/resolv.conf</code> mean?</summary>

Programs ask the stub resolver of `systemd-resolved` on this ship. It asks the real servers for them.
</details>

<details>
<summary>3. Where do you set a DNS server for the whole ship, without editing a packaged file?</summary>

In a drop-in such as `/etc/systemd/resolved.conf.d/10-lab.conf` with a `[Resolve]` section and `DNS=`. Then restart `systemd-resolved`.
</details>

<details>
<summary>4. What does a search domain do?</summary>

It adds a suffix to short names, so `db` is tried as `db.lab.example`.
</details>

<!-- astrona:playground:destroy -->
