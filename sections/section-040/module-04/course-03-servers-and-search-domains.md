# Servers And Search Domains

Astronaut, now you tell the clerk which directory to call and which suffix to add to short names. A **search domain** is a suffix. With the search domain `lab.example`, a program that asks for `db` is answered as if it had asked for `db.lab.example`.

## One setting for the whole ship

`systemd-resolved` reads `/etc/systemd/resolved.conf` and every `*.conf` file in `/etc/systemd/resolved.conf.d/`. Put your changes in a drop-in file. Never edit the packaged file, so an update cannot overwrite your work.

### Write the drop-in

Follow the three steps. Save this as `/etc/systemd/resolved.conf.d/10-lab.conf` (create the folder first with `sudo mkdir -p /etc/systemd/resolved.conf.d`):

<!-- astrona:playground:renew -->

```ini
[Resolve]
DNS=10.55.0.53
Domains=lab.example
```

Apply it:

```sh
sudo systemctl restart systemd-resolved
```

Then check the result:

```sh
resolvectl status | grep -E 'DNS Servers|DNS Domain'
getent hosts db
getent hosts www.lab.example
```

`DNS=` lists the servers, and `Domains=` lists the search domains. The first `getent` works only because of the search domain. The second works because the server is now known. If the old answer is in the cache, run `sudo resolvectl flush-caches`.

## One setting for one interface

Real ships often have several antennas, each with its own directory. Netplan can set the servers and search domains of one interface, and `systemd-networkd` hands them to the clerk for that interface only.

### What the Netplan form looks like

This is the shape of the settings. Do not apply it to the management interface:

```yaml
network:
  version: 2
  ethernets:
    dns0:
      nameservers:
        addresses: [10.55.0.53]
        search: [lab.example]
```

Use `resolvectl status dns0` to see what the clerk learned for that one interface. A routing domain with a leading tilde, such as `~lab.example`, sends only names under `lab.example` to that interface's servers and adds no search suffix.

## Common pitfalls

> [!WARNING]
> - **Editing the packaged file.** `/etc/systemd/resolved.conf` is replaced on package updates. Use a drop-in.
> - **Forgetting the restart.** The clerk reads the files only at start. Run `sudo systemctl restart systemd-resolved`.
> - **Confusing search and routing domains.** A plain domain adds a suffix. A domain with `~` only routes names.
> - **Testing too early.** Cached answers may hide the change. Flush the cache.

## Your mission: DNS Client Resolution Lab

You can now point the clerk at a server, add a search domain and pin one name in the pocket book. The graded mission asks for exactly that on a fresh ship: tell the resolver about the lab directory, make a short name work, and override one name locally.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop dns-resolver-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-04/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-04/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-044
astrona start dns-resolver-playground
```
