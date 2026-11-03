# Summary

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the harbour master that hands out call signs.

**From [The Lease Conversation](./course-01-the-lease-conversation.md):**

- DHCP is four messages: Discover, Offer, Request, Acknowledge. They use UDP ports 67 (server) and 68 (client).
- A lease carries the address, the prefix, the lease time, the router and the DNS servers. The client renews at half of the lease time.
- On Ubuntu Server `systemd-networkd` is the DHCP client. Netplan only writes the settings.

**From [A DHCP Client In Netplan](./course-02-a-dhcp-client-in-netplan.md):**

- `dhcp4: true` under the interface name asks for an IPv4 lease.
- Prove the lease with `ip -br addr`, `ip route`, `networkctl status` and the lease file in `/run/systemd/netif/leases/`.

**From [Overrides And Renewals](./course-03-overrides-and-renewals.md):**

- `dhcp4-overrides` with `use-routes`, `use-dns`, `use-hostname` and `route-metric` accepts only the parts of a lease you want.
- `networkctl renew` extends a lease and `networkctl reconfigure` starts again.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [DHCP Client Lab](./labs/lab-01/README.md) | Overrides And Renewals | get a lease on `dhcp0` and refuse the default route and the DNS servers from it |

If you skipped it, go back to it now. It is short, and it tests the whole client setup.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. What are the four DHCP messages, in order?</summary>

Discover, Offer, Request, Acknowledge.
</details>

<details>
<summary>2. Which Netplan key asks for an IPv4 lease?</summary>

`dhcp4: true` under the interface name.
</details>

<details>
<summary>3. How do you keep the address from a lease but not its default route?</summary>

Add `dhcp4-overrides` with `use-routes: false`, then run `sudo netplan apply`.
</details>

<details>
<summary>4. After how much of the lease time does a client first try to renew?</summary>

At half of the lease time.
</details>

<!-- astrona:playground:destroy -->
