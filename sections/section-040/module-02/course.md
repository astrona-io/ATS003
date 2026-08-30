# NTP Server Mode and Stratums

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-040/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-02/playground
> astrona destroy ntp-server-playground
> ```

The previous module set up a machine as an NTP **client** — it asks other servers for the time. This module is about the other direction: making a machine **answer** time queries for other machines.

Organisations run their own NTP servers so that hundreds of internal hosts sync against a couple of local servers instead of each reaching out to the public pool, and so that networks with restricted or no internet access still have a common time source. A typical shape:

```text
public pool  ->  2-4 internal NTP servers  ->  every other host
```

Two facts make this simpler than it sounds:

- There is **no separate server program**. The same `chronyd` that syncs your clock can also answer other machines' queries. A machine with good time is already capable of serving it.
- By default, `chronyd` **answers no one**. It drops every incoming client query until you explicitly permit a range of addresses with the `allow` directive. Turning a client into a server is mostly adding that one line.

The other half of this module is **stratum** — the number that says how far a source is from a real reference clock, and which this server will advertise to its clients.

## Learning objectives

After this module you can:

- Explain why an organisation runs internal NTP servers, and that chrony serves from the same daemon that acts as a client.
- Grant client access with the `allow` directive (and `deny` for exceptions), in the config file and at runtime with `chronyc`.
- Explain what `local stratum` does and when an isolated network needs it.
- Describe how stratum numbers relate a server to its clients and to a reference clock.
- Monitor a running server with `chronyc serverstats` and `chronyc clients`.
- State the firewall rule an NTP server needs and why `allow` alone is not enough.

## Before you start

This module assumes you have done the NTP **client** module — `server` / `pool` lines, `iburst`, `chronyc sources`, `chronyc tracking`, and slew-versus-step are used here without re-explaining. You should be able to open a shell, use `sudo`, edit a text file, and read a dotted IPv4 address with a prefix.

The playground is **two VMs** on an isolated segment, `192.168.101.0/24`:

- **`ntp-server`** (`192.168.101.10`) — chrony running with `local stratum 10` so it has a clock to serve, but **no `allow` line**, so it refuses every query. This is the machine you configure.
- **`ntp-client`** (`192.168.101.20`) — chrony already pointed at `192.168.101.10`. Its source sits in the `?` (refused) state until you open the server up.

Open a shell with `astrona ssh astro-ntp-server` or `astrona ssh astro-ntp-client` (confirm the exact names with `astrona list` if needed). Most commands are on **`ntp-server`**; the client is there to show whether the server is answering. `sudo` needs no password. Neither VM runs a firewall, so `allow` is the only access control in play.

## Where this fits

An internal NTP server sits between the public pool (or a hardware clock) and the rest of the estate, and it is a dependency for everything the client module listed — TLS, Kerberos, log correlation. It also touches the firewall modules directly: the server needs inbound UDP 123, the clients need outbound UDP 123.

Run **more than one** internal server — three or four is common. Clients list all of them; chrony compares their answers, discards any that disagree with the majority ("falsetickers"), and keeps working if one goes down. A single NTP server is a single point of failure for time across the whole network. For sub-microsecond needs (finance, telecom) NTP gives way to PTP (IEEE 1588) with hardware timestamping, which is a separate topic.

## Serving-side `chronyc`

The client module used `chronyc` to *query* the clock and *add* sources. The serving side adds four more subcommands, in the same query / control split:

| Kind | Subcommands | Purpose |
|---|---|---|
| **Query** | `serverstats`, `clients` | counters, and the list of hosts that have queried this server |
| **Control** | `allow <subnet>`, `deny <subnet>` | open or close access on the running daemon |

`allow` and `deny` exist both as `chronyc` subcommands (runtime only) and as `chrony.conf` directives (persistent). Same syntax, two lifetimes.

## Stratum

**Stratum** is how many steps a clock is from a hardware reference:

- **Stratum 0** — a reference clock itself: a GPS receiver, a radio clock, an atomic clock. Not on the network.
- **Stratum 1** — a server directly attached to a stratum-0 device.
- **Stratum 2** — a server that syncs to a stratum-1 server. And so on, each hop adding one.
- **Stratum 16** — means *not synchronised*. 15 is the highest usable value.

A server always advertises a stratum one higher than the source it is synced to, and its clients end up one higher again. If this server synced to a stratum-2 upstream, it would serve stratum 3, and its clients would be stratum 4.

This playground's server has **no upstream at all**. Left alone it would report stratum 16 (unsynchronised) and no client would trust it. The `local stratum 10` line in its config is what prevents that — covered in a moment. First, see the stratum it is claiming.

> [!TIP]
> **Try it — the server's own clock (on `ntp-server`)**
>
> ```sh
> chronyc tracking
> ```
>
> Expect a local reference and stratum 10:
>
> ```text
> Reference ID    : 7F7F0100 ()
> Stratum         : 10
> ...
> Leap status     : Normal
> ```
>
> `Reference ID : 7F7F0100` with an empty name is chrony referring to *its own* clock — there is no real upstream. `Stratum : 10` is the number the `local` directive told it to claim. Clients that sync to it will be stratum 11.

## The default: a chrony host answers no one

Before adding `allow`, the server is fully running and has a servable clock — and still refuses every client. The `ntp-client` VM has been pointing at it since boot, so its source shows the refusal.

> [!TIP]
> **Try it — the client is being turned away (on `ntp-client`)**
>
> ```sh
> chronyc sources -v
> ```
>
> Expect the source present but unusable:
>
> ```text
> MS Name/IP address         Stratum Poll Reach LastRx Last sample
> ===============================================================================
> ^? 192.168.101.10                0   6     0     -     +0ns[   +0ns] +/-    0ns
> ```
>
> `^?` means chrony has a source configured but has had no usable reply from it. `Reach 0` — none of its polls have been answered. The network path is fine; the server is choosing not to respond.

## Granting access with `allow`

The `allow` directive in `chrony.conf` permits NTP client queries from an address or range:

```text
allow 192.168.101.0/24      # a subnet
allow 192.168.101.20        # a single host
allow                       # everyone (use with care)
```

`deny` uses the same syntax to carve exceptions out of an allowed range; when both match, the more specific prefix wins. After editing the file, `chronyd` must be restarted to read it.

> [!TIP]
> **Try it — open the server to the segment (on `ntp-server`)**
>
> Uncomment the `allow` line already sitting in the config, or add it, then restart:
>
> ```sh
> sudo sed -i 's/^# *allow /allow /' /etc/chrony/chrony.conf
> grep '^allow' /etc/chrony/chrony.conf
> sudo systemctl restart chrony
> ```
>
> Then, on **`ntp-client`**, watch the source come alive:
>
> ```sh
> chronyc sources -v
> ```
>
> Within a poll or two the state flips from `^?` to `^*`:
>
> ```text
> ^* 192.168.101.10               10   6    17     6   +18us[  +42us] +/-  620us
> ```
>
> One line in the server's config changed the client from "refused" to "synchronised". The client is now stratum 11.

## Confirming from the server side

`serverstats` gives counters — NTP packets received and dropped, command packets, client-log records dropped. `clients` gives a table of the addresses that have queried this server, with request counts and last-seen times.

> [!TIP]
> **Try it — see the client in the server's logs (on `ntp-server`)**
>
> ```sh
> sudo chronyc serverstats
> sudo chronyc clients
> ```
>
> Expect non-zero received packets and the client listed:
>
> ```text
> NTP packets received       : 14
> NTP packets dropped        : 0
> ...
> ```
>
> ```text
> Hostname                      NTP   Drop Int IntL Last     Cmd   Drop Int  Last
> ===============================================================================
> 192.168.101.20                 14      0   6   -    23       0      0   -     -
> ```
>
> Before the `allow` line, `NTP packets received` sat near zero and `clients` was empty. Now the server is doing its job. Counts vary.

## Changing access at runtime

`chronyc` can also adjust access on the live daemon, without editing the file: `chronyc allow <subnet>`, `chronyc deny <subnet>`, `chronyc allow all`. Like the runtime source changes from the client module, these last only until `chronyd` restarts — useful for testing a rule before committing it.

> [!TIP]
> **Try it — narrow access to one host, live (on `ntp-server`)**
>
> ```sh
> sudo chronyc deny 192.168.101.0/24
> sudo chronyc allow 192.168.101.20
> sudo chronyc clients
> ```
>
> The `deny` closes the subnet and the `allow` re-opens just the one client address; the client keeps syncing because it is `192.168.101.20`. A restart (`sudo systemctl restart chrony`) discards both and the config file's `allow` line takes over again.

## `local stratum` — serving time with no upstream

`chronyd` will not serve time it does not have. On a normal server that is correct behaviour — if it loses its upstreams, it should stop handing out guesses. But a genuinely **isolated** network has no upstream to reach, and its hosts still need to agree with each other. `local stratum <n>` is the answer: it tells `chronyd` to act as a source even when unsynchronised, advertising stratum `<n>`.

Pick `<n>` on the high side — 10 or more. If a real upstream ever becomes reachable, its lower stratum wins automatically and `local` steps aside. Set it too low (say 1) and clients would prefer this made-up time over real servers.

> [!TIP]
> **Try it — change the advertised stratum and watch clients follow**
>
> On **`ntp-server`**, edit `local stratum 10` to `local stratum 8` and restart:
>
> ```sh
> sudo sed -i 's/^local stratum .*/local stratum 8/' /etc/chrony/chrony.conf
> sudo systemctl restart chrony
> ```
>
> Then on **`ntp-client`**:
>
> ```sh
> chronyc tracking | grep Stratum
> ```
>
> Expect the client's stratum to drop from 11 to 9 — always one above whatever the server now advertises. The number is a claim about distance from a reference clock, and `local` lets you set that claim by hand.

## Firewalls and NTP

NTP runs over **UDP port 123**. A server must accept inbound UDP 123, and its replies go out from 123. `allow` in `chrony.conf` is chrony's own access check — it does nothing about a packet filter in front of it. On a host running nftables, firewalld, or ufw, you also need a rule — one of these, matching whatever manages the firewall:

```sh
sudo nft add rule inet filter input udp dport 123 accept
sudo firewall-cmd --permanent --add-service=ntp && sudo firewall-cmd --reload
sudo ufw allow 123/udp
```

This playground runs no firewall, so `allow` was the only gate. On a real server, "I added `allow` and clients still can't reach me" is almost always the missing firewall rule.

> [!WARNING]
> **Common pitfalls**
>
> - **Forgetting `allow`.** A freshly configured chrony server answers nobody until an `allow` line names their range. This is the most common "my NTP server isn't working".
> - **Forgetting the firewall.** `allow` is chrony's check, not the kernel's. The server still needs inbound UDP 123 through nftables / firewalld / ufw.
> - **`chronyc allow` treated as permanent.** Runtime access changes vanish on restart. Put the rule in `chrony.conf`.
> - **Serving `local stratum` when you have real upstreams.** `local` only applies while unsynchronised, but relying on it hides the fact that a server with a genuine internet source has lost sync. Use it only for truly isolated networks.
> - **`local stratum` set too low.** A small number makes clients prefer this server's unverified time over real, lower-stratum sources elsewhere. Keep it at 10 or above.
> - **A server that is not itself synced.** Without `local`, a server whose own `chronyc tracking` shows `Leap status : Not synchronised` serves nothing. Check the server's own sync before blaming the clients.
> - **One server only.** No redundancy, no falseticker detection. Run several and list them all on every client.
