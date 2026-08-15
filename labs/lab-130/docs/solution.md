# Solution

## Step 1: Find the local, private address

```bash
ip addr show
```

Or, for a quicker single-line answer across all interfaces:

```bash
hostname -I
```

Check `man hostname` for `-I` — it prints all network addresses of the host, space-separated, skipping loopback. Look for an address in one of the private ranges (`10.x.x.x`, `172.16.x.x`–`172.31.x.x`, `192.168.x.x`) bound to your primary interface — this is the address other devices on the same LAN use to reach this machine, and it is the only address the machine itself actually "knows" about without asking anyone else.

```text
192.168.10.55
```

## Step 2: Understand why this number is not the public IP

Nothing about the private address changes based on what's on the other side of the router — it's purely local configuration. If terminal is behind a NAT gateway, any packet leaving the network gets its source address rewritten by that gateway to the gateway's own public IP before it reaches the internet; return traffic gets translated back on the way in. terminal itself has no visibility into what that translated address actually is — it has to ask something outside the NAT boundary.

## Step 3: Query an HTTP-based external echo service

```bash
curl -s ifconfig.me
```

Or an equivalent alternative service, useful to have a second option in case one is unreachable:

```bash
curl -s icanhazip.com
```

Check `man curl` for `-s` — silent mode, suppressing the progress meter so the output is just the bare IP address, easy to capture in a script. Both of these services work the same way: they're plain HTTP endpoints that simply echo back whatever source IP the request actually arrived from — which, having passed through the NAT gateway, is the public address, not the private one.

```text
203.0.113.44
```

## Step 4: Query a DNS-based alternative that doesn't depend on HTTP

```bash
dig +short myip.opendns.com @resolver1.opendns.com
```

Check `man dig` for `+short` (strips the verbose header/footer, prints just the answer) and the `@server` syntax (sends the query directly to a specific resolver — `resolver1.opendns.com`, OpenDNS's public resolver — rather than whatever resolver your system is normally configured to use). This works because OpenDNS's resolver, seeing the query arrive with your NAT gateway's public source address, has special-cased the hostname `myip.opendns.com` to answer with the querying address itself instead of a normal, static DNS record.

```text
203.0.113.44
```

This should match the HTTP-based answer from Step 3 — both are reporting the same NAT-translated public address, just discovered via two independent protocols (HTTP vs. DNS), which is exactly the point: if one method is blocked by an intervening firewall or proxy, the other is a genuinely independent fallback rather than just a different-looking way of asking the same dependent question.

## Step 5: Record both addresses and tie them together conceptually

```text
Local (private, RFC1918):  192.168.10.55   -- meaningful only inside this LAN
Public (NAT-translated):   203.0.113.44    -- what the internet actually sees
```

One public IP (`203.0.113.44`) can simultaneously front every other device on the same network — a phone, a laptop, a smart TV — each with its own distinct private address that the outside world never sees directly. This is the essence of NAT: address conservation by translating many private addresses down to few (often one) public addresses at the network boundary.

Persist both answers so they can be checked:

```bash
hostname -I | awk '{print $1}' > /opt/course/private_ip
curl -s ifconfig.me > /opt/course/public_ip
```

## Verification

```bash
ip addr show | grep 'inet '
hostname -I
curl -s ifconfig.me
curl -s icanhazip.com
dig +short myip.opendns.com @resolver1.opendns.com
```

Expected: the local command outputs a private RFC1918 address; all three external lookups agree on the same public address, and that public address is visibly different from the private one.

```bash
cat /opt/course/private_ip
# 192.168.10.55
cat /opt/course/public_ip
# 203.0.113.44
```

## Command Summary

```bash
ip addr show
hostname -I

curl -s ifconfig.me
curl -s icanhazip.com

dig +short myip.opendns.com @resolver1.opendns.com

hostname -I | awk '{print $1}' > /opt/course/private_ip
curl -s ifconfig.me > /opt/course/public_ip
```
