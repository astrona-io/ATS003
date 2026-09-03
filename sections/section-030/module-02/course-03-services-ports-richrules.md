# Part 3 — Services, ports, and rich rules

> Prerequisite: [Part 2 — Zones](./course-02-zones.md). Next: [Part 4 — Runtime, permanent, and operations](./course-04-runtime-permanent-operations.md).

A zone decides *who* is handled by a policy. This part is about *what that policy allows*: named services, raw ports and ranges, and — when "allow this service" is too blunt — rich rules that pin an allow or deny to a specific source, with logging and rate limits.

## What a service definition contains

A firewalld **service** is a small XML file naming everything one network service needs open:

```xml
<!-- /usr/lib/firewalld/services/ssh.xml -->
<service>
  <short>SSH</short>
  <description>Secure Shell (SSH) is a protocol ...</description>
  <port protocol="tcp" port="22"/>
</service>
```

A service can list several ports, both protocols, a **conntrack helper module** (`<module name="nf_conntrack_ftp"/>`), and a fixed **destination** address. Allowing the service in a zone opens *all* of that at once — which is the point: you say `--add-service=samba` instead of remembering four ports across TCP and UDP.

```sh
sudo firewall-cmd --get-services                 # every predefined service name
sudo firewall-cmd --info-service=ssh             # what one service opens
```

Roughly 100 services ship predefined (`ssh`, `http`, `https`, `dns`, `dhcpv6-client`, `cockpit`, `samba`, …). Define your own:

```sh
sudo firewall-cmd --permanent --new-service=myapp
sudo firewall-cmd --permanent --service=myapp --add-port=9000/tcp
sudo firewall-cmd --permanent --service=myapp --set-description="My app"
sudo firewall-cmd --reload
```

That writes `/etc/firewalld/services/myapp.xml`, after which `myapp` is a name you can `--add-service` into any zone.

## Services vs raw ports

| | `--add-service=<name>` | `--add-port=<port>/<proto>` |
|---|---|---|
| Opens | whatever the service XML lists | exactly that port/range |
| Readable later | `--list-services` shows a name | `--list-ports` shows a bare number |
| Best for | anything with a standard name | one-off / non-standard ports |

Prefer the service when one exists — `--list-all` on a zone full of named services documents itself; a zone full of `8080/tcp 9090/tcp 5000/tcp` does not.

### Ports and ranges

Port syntax is `<number>[-<number>]/<protocol>`:

```sh
sudo firewall-cmd --zone=public --add-port=8080/tcp          # one port
sudo firewall-cmd --zone=public --add-port=30000-30100/udp   # a range
sudo firewall-cmd --zone=public --add-protocol=gre           # a whole L4 protocol, no port
sudo firewall-cmd --zone=public --add-source-port=68/udp     # match on SOURCE port instead
```

To see a change take effect you need traffic that actually passes through a zone. Traffic to `127.0.0.1` does not — firewalld always allows loopback — so the checkpoint uses the VM's other address, `192.168.90.10`, whose interface is in `public`. Start a listener first:

```sh
python3 -m http.server 8080
```

> [!TIP]
> **Try it — a port is closed, then open it**
>
> From a second SSH session (or with the listener backgrounded by `&`):
>
> ```sh
> curl -sS --max-time 3 http://192.168.90.10:8080/ ; echo "exit: $?"
> sudo firewall-cmd --zone=public --add-port=8080/tcp
> curl -sS --max-time 3 http://192.168.90.10:8080/ | head -c 40 ; echo
> ```
>
> Expect the first `curl` to time out and the second to succeed:
>
> ```text
> curl: (28) Operation timed out after 3001 milliseconds
> exit: 28
> <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
> ```
>
> The listener ran the whole time; only the zone changed. `public` had no rule for TCP 8080, so the request was rejected until `--add-port` allowed it. This change is **runtime-only** — Part 4 shows it vanish on `--reload`.

## Forward ports

A zone can redirect an incoming port to another port, or to another host (DNAT):

```sh
# incoming :80 on this host -> local :8080
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080
# incoming :80 -> :80 on another machine (needs masquerade on for the return path)
sudo firewall-cmd --zone=public --add-masquerade
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=80:toaddr=10.0.0.5
```

## Rich rules — when "allow the service" is too broad

`--add-service=http` opens port 80 to **everyone the zone handles**. A **rich rule** is one structured rule that narrows that: a source, a service or port, an action, and optionally logging or a rate limit — without creating a whole new zone.

Skeleton:

```text
rule family="ipv4" source address="<cidr>" service name="<svc>" [log prefix="..." level="..."] [limit value="n/unit"] <accept|reject|drop>
```

Examples:

```sh
# only 192.168.90.0/24 may reach http in this zone
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.90.0/24" service name="http" accept'

# log and drop SSH attempts from one bad host, max 5 log lines a minute
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.7" service name="ssh" log prefix="ssh-drop " level="warning" limit value="5/m" drop'
```

Rich rules are evaluated before the zone's plain service/port allows, so a rich `accept` for one source plus **no** plain `--add-service` gives you "this service, that source only." Add the plain service too and it is open to everyone *plus* logged for the specific source.

> [!TIP]
> **Try it — a rich rule scopes a port to one source network**
>
> With the `8080/tcp` port from the earlier checkpoint removed (`sudo firewall-cmd --zone=public --remove-port=8080/tcp`) and the listener still running:
>
> ```sh
> sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.90.0/24" port port="8080" protocol="tcp" accept'
> sudo firewall-cmd --zone=public --list-rich-rules
> curl -sS --max-time 3 http://192.168.90.10:8080/ | head -c 40 ; echo
> ```
>
> The request from `192.168.90.10` is inside `192.168.90.0/24`, so the rich rule accepts it. A request from any other source would still be rejected by the zone's target. Remove it with the matching `--remove-rich-rule='...'` (same rule text).

> *A service is a named bundle of ports; prefer it over raw `--add-port` so the zone documents itself. A rich rule is the tool when an allow or deny must be scoped to a specific source, logged, or rate-limited.*

## Reference

- `man 5 firewalld.service` — the service XML schema (`port`, `protocol`, `module`, `destination`).
- `man 5 firewalld.richlanguage` — the full rich-rule grammar: `source`, `destination`, `service`, `port`, `forward-port`, `masquerade`, `log`, `audit`, `limit`, actions.
- `firewall-cmd --list-all` — read a zone's services, ports, forward-ports, and rich rules together.
- **firewalld.org, "Rich Language"** (`https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html`) — annotated examples.
