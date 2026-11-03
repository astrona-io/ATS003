# Who Answers A Name

Astronaut, two tools can look up the same name and give different answers. That is not a bug. They ask different people. This part shows who is asked, in which order, and which tool asks the same way your applications do.

## The routine of the directory clerk

When a program asks for a name, the C library follows the order written in `/etc/nsswitch.conf` (the Name Service Switch). The `hosts:` line lists the sources. Ubuntu 24.04 normally has `files dns`, which means: the pocket address book (`/etc/hosts`) first, then the directory (DNS).

### See it in your playground

<!-- astrona:playground:renew -->

Show the line that sets the order:

```sh
grep '^hosts:' /etc/nsswitch.conf
```

Then ask the same way an application does:

```sh
getent hosts localhost
```

`getent hosts` walks the `hosts:` sources in order and prints the first answer. This is the tool that matches what `ping`, `curl` and `ssh` will see.

## Why dig can disagree

`dig` skips the routine. It builds a DNS question itself and sends it to a server. It never reads `/etc/hosts` and it ignores `nsswitch.conf`. That makes `dig` a good tool for asking the directory, and a bad tool for asking "what will my program see".

### Compare the two

The playground's server knows `db.lab.example`. Ask it directly:

```sh
dig +short @10.55.0.53 db.lab.example
```

The answer is `203.0.113.20`. Now ask the way an application does:

```sh
getent hosts db.lab.example
```

At first the ship has not been told about this directory, so `getent` prints nothing. The ship's clerk does not know who to call yet. The next parts fix that.

## Pin a name in the pocket address book

An entry in `/etc/hosts` wins over DNS, because `files` comes first. Add a line, test it, and compare:

```sh
echo '198.51.100.7 www.lab.example' | sudo tee -a /etc/hosts
getent hosts www.lab.example
dig +short @10.55.0.53 www.lab.example
```

`getent` shows `198.51.100.7` and `dig` shows `203.0.113.10`. Remove the line when you are done:

```sh
sudo sed -i '/www.lab.example/d' /etc/hosts
```

## Common pitfalls

> [!WARNING]
> - **Testing with `dig` only.** A name can work in `dig` and fail in an application, or the reverse. Always check with `getent hosts`.
> - **Forgetting the pocket book.** A stale `/etc/hosts` line silently beats a correct DNS record.
> - **Changing `nsswitch.conf` for no reason.** Keep `files dns` unless you have a reason. A wrong order breaks every lookup.
