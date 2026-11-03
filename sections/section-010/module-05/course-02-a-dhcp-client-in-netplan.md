# A DHCP Client In Netplan

Astronaut, turning on DHCP takes one line in the flight manual. The skill is in proving what the lease did. This part writes the Netplan file, applies it, and reads the result from four angles.

## Turn it on

In Netplan, `dhcp4: true` asks for an IPv4 lease. The interface name goes under `ethernets:`, and the name must match the real antenna.

### Write the file

<!-- astrona:playground:renew -->

Save this as `/etc/netplan/70-dhcp0.yaml`:

```yaml
network:
  version: 2
  ethernets:
    dhcp0:
      dhcp4: true
```

Apply it. Netplan warns when a file is readable by others, so set safe permissions first:

```sh
sudo chmod 600 /etc/netplan/70-dhcp0.yaml
sudo netplan apply
```

Then check the result:

```sh
ip -br addr show dhcp0
```

The antenna should now hold an address from `10.77.0.100` to `10.77.0.149` with the prefix `/24`. If it has none, wait a few seconds and run the command again, because the exchange takes a moment.

## Read the lease from four angles

An address is only the start. The lease also set a lane and a directory.

### Angle 1 and 2: addresses and routes

```sh
ip -4 addr show dhcp0
ip route show dev dhcp0
```

In the address output, the word `dynamic` and a finite `valid_lft` tell you the address is a lease. The route output lists the sector route and, because the server gave a router, a default route through `10.77.0.1`.

### Angle 3: what networkd says

```sh
networkctl status dhcp0
```

This shows the state, the address and the DHCP server. It also lists the DNS servers learned from the lease.

### Angle 4: the lease file

`systemd-networkd` writes the raw lease into a file named after the interface index:

```sh
cat /run/systemd/netif/leases/$(cat /sys/class/net/dhcp0/ifindex)
```

The file lists `ADDRESS`, `ROUTER`, `DNS`, `LIFETIME` and other values. Because it lives in `/run`, it disappears at reboot, and the client simply asks again.

## Watch the conversation

To see DORA with your own eyes, start a recorder on the client antenna in one shell, and trigger a renewal from another (the next part shows `networkctl renew`). The filter keeps only DHCP packets:

```sh
sudo timeout 30 tcpdump -ni dhcp0 'udp port 67 or udp port 68'
```

## Common pitfalls

> [!WARNING]
> - **A wrong interface name.** `dhcp4: true` under a name that does not exist does nothing. Check the name with `ip -br link`.
> - **YAML indentation.** Netplan uses spaces, never tabs. Run `sudo netplan try` or `sudo netplan generate` to find errors.
> - **Not looking at the routes.** A lease can install a default route that competes with the one you already have. Always read `ip route`.
> - **Editing the cloud-init file.** The management interface's Netplan file belongs to cloud-init. Add a new file instead.
