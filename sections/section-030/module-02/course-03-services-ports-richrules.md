# Services, Ports And Rich Rules

Astronaut, a zone decides *who* a shield preset applies to. This part is about *what that preset lets through*: named services, raw ports and port ranges, port forwards, and, when "allow this service" is too blunt, **rich rules** that tie an allow or a deny to one source, with logging and rate limits.

## What a service contains

A firewalld **service** is a named bundle of radio channels (ports). This section shows what the bundle looks like on disk, and how to list, read and create services.

### A service file

A service is a small XML file (a text format of nested tags) naming everything one network service needs open:

```xml
<!-- /usr/lib/firewalld/services/ssh.xml -->
<service>
  <short>SSH</short>
  <description>Secure Shell (SSH) is a protocol ...</description>
  <port protocol="tcp" port="22"/>
</service>
```

A service can list several ports, both TCP (Transmission Control Protocol, a steady two-way conversation between programs) and UDP, a **connection tracking helper module** (`<module name="nf_conntrack_ftp"/>`) and a fixed **destination** address. Allowing the service in a zone opens all of that at once. That is the point: you write `--add-service=samba` instead of remembering four ports across TCP and UDP.

### List and read services

```sh
sudo firewall-cmd --get-services                 # every predefined service name
sudo firewall-cmd --info-service=ssh             # what one service opens
```

About 100 services come ready-made (`ssh`, `http`, `https`, `dns`, `dhcpv6-client`, `cockpit`, `samba` and more).

### Define your own service

```sh
sudo firewall-cmd --permanent --new-service=myapp
sudo firewall-cmd --permanent --service=myapp --add-port=9000/tcp
sudo firewall-cmd --permanent --service=myapp --set-description="My app"
sudo firewall-cmd --reload
```

That writes `/etc/firewalld/services/myapp.xml`. After the reload, `myapp` is a name you can `--add-service` into any zone.

## Services or raw ports

Both open channels in a zone. The difference is how readable the zone stays afterwards.

### Which one to use

| | `--add-service=<name>` | `--add-port=<port>/<proto>` |
|---|---|---|
| Opens | whatever the service file lists | exactly that port or range |
| Readable later | `--list-services` shows a name | `--list-ports` shows a bare number |
| Best for | anything with a standard name | one-off or unusual ports |

Prefer the service when one exists. `--list-all` on a zone full of named services explains itself; a zone full of `8080/tcp 9090/tcp 5000/tcp` does not.

### Ports and ranges

The port syntax is `<number>[-<number>]/<protocol>`:

```sh
sudo firewall-cmd --zone=public --add-port=8080/tcp          # one port
sudo firewall-cmd --zone=public --add-port=30000-30100/udp   # a range
sudo firewall-cmd --zone=public --add-protocol=gre           # a whole L4 protocol, no port
sudo firewall-cmd --zone=public --add-source-port=68/udp     # match on SOURCE port instead
```

GRE is a tunnelling protocol with no ports, so you allow the whole protocol.

## Open a closed port

Now see a zone change make a port answer. Traffic to `127.0.0.1` does not pass through a zone, because firewalld always allows loopback (the ship's internal intercom). So this test uses the playground's other address, `192.168.90.10`, whose interface is in `public`.

### Start a listener

<!-- astrona:playground:renew -->

Start a web server on port 8080 in one SSH (Secure Shell, the sealed communications channel between ships) session (or add `&` to run it in the background):

```sh
python3 -m http.server 8080
```

### The port is closed, then open

From a second SSH session:

```sh
curl -sS --max-time 3 http://192.168.90.10:8080/ ; echo "exit: $?"
sudo firewall-cmd --zone=public --add-port=8080/tcp
curl -sS --max-time 3 http://192.168.90.10:8080/ | head -c 40 ; echo
```

The first `curl` times out and the second one succeeds:

```text
curl: (28) Operation timed out after 3001 milliseconds
exit: 28
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN
```

The web server ran the whole time; only the zone changed. `public` had no rule for TCP port 8080, so the request was turned away until `--add-port` allowed it. This change is **runtime only**: the next `firewall-cmd --reload` removes it.

## Forward ports

A zone can also redirect an incoming port to another port, or to another machine. Redirecting to another machine rewrites the destination address (destination NAT, the relay station sending the signal on to another ship):

```sh
# incoming :80 on this host -> local :8080
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=8080
# incoming :80 -> :80 on another machine (needs masquerade on for the return path)
sudo firewall-cmd --zone=public --add-masquerade
sudo firewall-cmd --zone=public --add-forward-port=port=80:proto=tcp:toport=80:toaddr=10.0.0.5
```

## Rich rules: when "allow the service" is too broad

`--add-service=http` opens port 80 to **everyone the zone handles**. A **rich rule** narrows that down. It is one structured rule with a source, a service or port, an action, and optionally logging or a rate limit, without creating a whole new zone.

### The shape of a rich rule

```text
rule family="ipv4" source address="<cidr>" service name="<svc>" [log prefix="..." level="..."] [limit value="n/unit"] <accept|reject|drop>
```

`<cidr>` is an address range written with a prefix length, such as `192.168.90.0/24`.

Examples:

```sh
# only 192.168.90.0/24 may reach http in this zone
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.90.0/24" service name="http" accept'

# log and drop SSH attempts from one bad host, max 5 log lines a minute
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.7" service name="ssh" log prefix="ssh-drop " level="warning" limit value="5/m" drop'
```

### Rich rules come first

Rich rules are checked before the zone's plain service and port allows. So a rich `accept` for one source, with **no** plain `--add-service`, gives you "this service, from that source only". Add the plain service as well, and the service is open to everyone, *plus* logged for that one source.

### Scope a port to one source network

First remove the raw port you opened above, so only the rich rule decides:

```sh
sudo firewall-cmd --zone=public --remove-port=8080/tcp
```

Then, with the web server still running:

```sh
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.90.0/24" port port="8080" protocol="tcp" accept'
sudo firewall-cmd --zone=public --list-rich-rules
curl -sS --max-time 3 http://192.168.90.10:8080/ | head -c 40 ; echo
```

The request from `192.168.90.10` is inside `192.168.90.0/24`, so the rich rule accepts it. A request from any other source would still be turned away by the zone's target. Remove the rule with `--remove-rich-rule='...'` and the same rule text.

## Common pitfalls

> [!WARNING]
> - **Testing against `127.0.0.1`.** firewalld always allows loopback, so a loopback test proves nothing about a zone. Use an address on an interface in the zone.
> - **A wall of raw ports.** Prefer named services; `--list-all` then explains itself.
> - **Removing a rich rule with different text.** `--remove-rich-rule` needs exactly the same rule text you added.

> *A service is a named bundle of ports; prefer it over a raw `--add-port`, so the zone explains itself. A rich rule is the tool when an allow or a deny must be limited to one source, logged or rate-limited.*
