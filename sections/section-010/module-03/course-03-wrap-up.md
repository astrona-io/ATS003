# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the two addresses a machine has: the private call sign on its own antenna, and the public call sign the galaxy sees after NAT.

**From [Private Call Signs And The Relay Station](./course-01-private-addresses-and-nat.md):**

- The private IPv4 ranges (RFC 1918) are `10.0.0.0/8`, `172.16.0.0/12` and `192.168.0.0/16`. They are never routed on the public internet.
- With SNAT (also called masquerading or PAT), a router replaces the private source address with a public one. The router does this, not the Linux machine.
- The public address does not appear in `ip addr show`, because it lives on the router.
- The `default via` gateway in `ip route show` is normally a private address too. `ip route get 1.1.1.1` shows the way out without sending a packet.

**From [Ask The Galaxy What It Sees](./course-02-ask-what-the-internet-sees.md):**

- Only an outside service can tell you your public egress address: over HTTP (`curl -s https://ifconfig.me`) or over DNS (`dig +short TXT o-o.myaddr.l.google.com @ns1.google.com`).
- Add `--max-time` to `curl` so a blocked request fails fast.
- HTTP and DNS answers can differ, and IPv4 and IPv6 (`curl -4`, `curl -6`) can use different public addresses.
- A discovered public address proves nothing about incoming reachability.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Public IP Discovery Behind NAT Lab](./labs/lab-01/README.md) | Ask The Galaxy What It Sees | find the private and the public address and record each one exactly |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Is <code>172.20.4.9</code> a private address?</summary>

Yes. It lies in `172.16.0.0/12`, which covers `172.16.x.x` to `172.31.x.x`.
</details>

<details>
<summary>2. <code>ip route show</code> says <code>default via 10.0.0.1</code>. Is <code>10.0.0.1</code> your public address?</summary>

No. It is the default gateway, normally a private address on the local network. The public address is applied by NAT further along the path.
</details>

<details>
<summary>3. Why can't <code>ip addr show</code> tell you the public address?</summary>

Because the router does the translation. The public address sits on the router, not on any interface of your machine.
</details>

<details>
<summary>4. <code>curl -s https://ifconfig.me</code> and the <code>dig</code> question return different addresses. Is something broken?</summary>

No. HTTP and DNS traffic can leave the network by different paths, proxies or forwarders, so each service can see a different address.
</details>

<details>
<summary>5. You found your public egress address. Can people on the internet now connect to your machine?</summary>

Not necessarily. Discovery only tests outgoing connections. Incoming traffic can still be blocked by a firewall, a missing port forward, carrier-grade NAT or cloud security controls.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy public-ip-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-013
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command for its folder, `sections/section-010/module-03/playground`. It always starts clean, so nothing you broke carries over.
