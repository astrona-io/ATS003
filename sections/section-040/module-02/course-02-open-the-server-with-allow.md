# Open The Server With `allow`

Astronaut, your server ship has good time and refuses to share it. One line changes that: `allow` lets other ships set their clocks from yours. In this part you add it, prove from both ships that it works, and then change access on the running service without touching the file.

## Granting access with `allow`

The `allow` directive in `chrony.conf` permits NTP client queries from an address or a range. NTP, the Network Time Protocol, is the time signal ships use to keep their clocks in step. `chronyd`, the clockmaster, checks every incoming query against these lines.

### The forms of `allow`

```text
allow 192.168.101.0/24      # a subnet
allow 192.168.101.20        # a single host
allow                       # everyone (use with care)
```

`deny` uses the same syntax to cut exceptions out of an allowed range. When both match, the more specific prefix wins. After editing the file, restart `chronyd` so it reads the file again.

### Open the server to the segment

<!-- astrona:playground:renew -->

On `ntp-server`, uncomment the `allow` line already sitting in the configuration file (or add it), then restart:

```sh
sudo sed -i 's/^# *allow /allow /' /etc/chrony/chrony.conf
grep '^allow' /etc/chrony/chrony.conf
sudo systemctl restart chrony
```

Then, on **`ntp-client`**, watch the source come alive:

```sh
chronyc sources -v
```

Within a poll or two the state flips from `^?` to `^*`:

```text
^* 192.168.101.10               10   6    17     6   +18us[  +42us] +/-  620us
```

One line in the server's configuration file changed the client from "refused" to "synchronised". The client is now stratum 11.

## Confirming from the server side

The client's view is one half of the proof. The server keeps its own records of who asked for the time, and `chronyc` can show them.

### Two server-side reports

- `serverstats` gives counters: NTP packets received and dropped, command packets, and client log records dropped.
- `clients` gives a table of the addresses that have queried this server, with request counts and last-seen times.

### See the client in the server's records

On `ntp-server`:

```sh
sudo chronyc serverstats
sudo chronyc clients
```

Expect received packets above zero and the client listed:

```text
NTP packets received       : 14
NTP packets dropped        : 0
...
```

```text
Hostname                      NTP   Drop Int IntL Last     Cmd   Drop Int  Last
===============================================================================
192.168.101.20                 14      0   6   -    23       0      0   -     -
```

Before the `allow` line, `NTP packets received` sat near zero and `clients` was empty. Now the server is doing its job. Your counts will be different.

## Changing access at runtime

`chronyc` can also change access on the live service, without editing the file: `chronyc allow <subnet>`, `chronyc deny <subnet>`, `chronyc allow all`. Like a source added with `chronyc add`, these changes last only until `chronyd` restarts. They are useful for testing a rule before you write it into the file.

### Narrow access to one host, live

On `ntp-server`:

```sh
sudo chronyc deny 192.168.101.0/24
sudo chronyc allow 192.168.101.20
sudo chronyc clients
```

The `deny` closes the subnet, and the `allow` opens it again for just the one client address. The client keeps syncing, because it is `192.168.101.20`. A restart (`sudo systemctl restart chrony`) throws away both changes, and the `allow` line in the configuration file takes over again.

## Common pitfalls

> [!WARNING]
> - **Forgetting the restart.** chrony reads `chrony.conf` only when it starts. An `allow` line added without `sudo systemctl restart chrony` does nothing.
> - **`chronyc allow` treated as permanent.** Runtime access changes vanish on restart. Put the rule in `chrony.conf`.
> - **A server that is not itself synced.** Without `local stratum`, a server whose own `chronyc tracking` shows `Leap status : Not synchronised` serves nothing. Check the server's own sync before you blame the clients.
> - **Leaving public sources on the client.** A client that should use only your internal server must not keep its default `pool` lines active; comment them out.

## Your mission: NTP Server Mode and Stratums Lab

You can now open a chrony server to a subnet and prove from both machines that a client syncs through it. Now prove it in a graded mission: turn one machine into the internal time server for its subnet, and point a second machine at it instead of the public pool.

The mission runs on its own training ships, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ntp-server-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-02/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-042
astrona start ntp-server-playground
```
