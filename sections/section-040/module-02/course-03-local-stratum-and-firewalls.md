# Local Stratum And Firewalls

Astronaut, two more things decide whether your time server really serves. A server with no upstream beacon needs permission to broadcast its own clock, and the ship's shields must let the time signal through. This part covers both.

## `local stratum`: serving time with no upstream

`chronyd`, the clockmaster, will not serve time it does not have. On a normal server that is the right behaviour: if it loses its upstream sources, it should stop handing out guesses. But a truly **isolated** network has no upstream to reach, and its machines still need to agree with each other.

### What the directive does

`local stratum <n>` is the answer. It tells `chronyd` to act as a time source even when it is not synchronised, and to advertise stratum `<n>`. Stratum is how many relays the time passed through since the master clock.

Pick `<n>` on the high side: 10 or more. If a real upstream ever becomes reachable, its lower stratum wins automatically and `local` steps aside. Set it too low (say 1) and clients would prefer this made-up time over real servers.

### Change the advertised stratum and watch clients follow

<!-- astrona:playground:renew -->

On **`ntp-server`**, change `local stratum 10` to `local stratum 8` and restart:

```sh
sudo sed -i 's/^local stratum .*/local stratum 8/' /etc/chrony/chrony.conf
sudo systemctl restart chrony
```

Then, on **`ntp-client`**:

```sh
chronyc tracking | grep Stratum
```

Look at the `Stratum` line: the client's stratum drops from 11 to 9, always one above whatever the server now advertises. The number is a claim about distance from a reference clock, and `local` lets you set that claim by hand. This only works while the server allows the client, so the `allow 192.168.101.0/24` line must still be active.

## Firewalls and NTP

NTP runs over User Datagram Protocol (UDP) port 123; a port is a radio channel on the ship's antenna. `allow` in `chrony.conf` is chrony's own access check. It does nothing about the ship's shields, the packet filter in front of it.

### The rule a server needs

A server must accept incoming UDP traffic on port 123, and its replies go out from port 123. On a machine running nftables, firewalld or ufw, you also need a firewall rule. Use one of these, matching whatever manages the firewall:

```sh
sudo nft add rule inet filter input udp dport 123 accept
sudo firewall-cmd --permanent --add-service=ntp && sudo firewall-cmd --reload
sudo ufw allow 123/udp
```

The `nft` line assumes an `inet filter` table with an `input` chain already exists.

### Why the playground did not need it

Your playground runs no firewall, so `allow` was the only gate. On a real server, "I added `allow` and clients still cannot reach me" is almost always the missing firewall rule.

## Common pitfalls

> [!WARNING]
> - **Forgetting the firewall.** `allow` is chrony's check, not the kernel's. The server still needs incoming UDP port 123 through nftables, firewalld or ufw.
> - **Serving `local stratum` when you have real upstreams.** `local` only applies while the server is not synchronised, but relying on it hides the fact that a server with a real internet source has lost sync. Use it only for truly isolated networks.
> - **`local stratum` set too low.** A small number makes clients prefer this server's unchecked time over real, lower-stratum sources elsewhere. Keep it at 10 or above.
