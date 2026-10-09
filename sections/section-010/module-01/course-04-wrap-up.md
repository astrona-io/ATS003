# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the antennas on your ship's communications array (network interfaces) and the call signs they carry (IP addresses).

**From [Antennas And Their State](./course-01-antennas-and-their-state.md):**

- `ip link` shows the interface itself, `ip addr` shows its addresses, and `ip route` shows the routing table. `show` reads; `add`, `del` and `set` change things and need `sudo`.
- `ip link show` prints each interface's state, MAC address and MTU. The loopback interface has an all-zero MAC address.
- An interface can be `UP` with no address at all. `UP` is only the administrative state.
- Enabled (`UP`), connected (`LOWER_UP`) and reachable are three different things. Only an answer to a real signal proves reachability.
- `ip link set <name> down` and `up` switch an interface off and on. Never do it to the interface that carries your SSH session.

**From [Call Signs, Sectors And The Way Out](./course-02-call-signs-sectors-and-the-way-out.md):**

- An IPv4 address is 32 bits in four dotted numbers; an IPv6 address is 128 bits in hexadecimal groups, where `::` may appear only once.
- The prefix length says how many leading bits are the network part. Two addresses are on the same network only if their network bits match at the same prefix length.
- Every IPv6 interface that is `UP` gives itself a link-local `fe80::` address, valid only on its own segment.
- `ip route show` prints the routing table. The `default via` line is the default gateway, used when no more specific route matches.
- The loopback interface `lo` (`127.0.0.1/8`, `::1/128`) always answers, and its traffic never leaves the machine.

**From [Runtime Changes And Persistent Configuration](./course-03-runtime-and-persistent-configuration.md):**

- `ip addr add`, `ip addr del` and `ip link set` change only the running kernel. A reboot clears them.
- Persistent addressing goes through NetworkManager, Netplan or `systemd-networkd`, which write the configuration to disk and apply it at every boot.
- Only one of these systems should manage an interface.
- A grader checks persistence by looking in the on-disk configuration, not in `ip addr show`.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [IPv4 & IPv6 Interface Configuration Lab](./labs/lab-01/README.md) | Runtime Changes And Persistent Configuration | add a second IPv4 and an IPv6 address, make them persistent, and name the address in `/etc/hosts` |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. <code>ip link show</code> says an interface is <code>UP</code> and <code>LOWER_UP</code>. Can other machines reach it?</summary>

Not necessarily. Those flags report only that the interface is switched on and has a carrier. Reachability also needs an address (`ip addr show`), a route (`ip route show`), a working path and a host that answers.
</details>

<details>
<summary>2. Are <code>10.4.1.9/24</code> and <code>10.4.2.9/24</code> on the same network? And at <code>/16</code>?</summary>

At `/24`, no: the network parts `10.4.1` and `10.4.2` differ, so traffic between them is routed. At `/16`, yes: only `10.4` counts, and it matches.
</details>

<details>
<summary>3. Is <code>2001:db8::1::2</code> a valid IPv6 address?</summary>

No. `::` may appear only once, because otherwise nobody can tell how many zero groups each `::` stands for.
</details>

<details>
<summary>4. What does the <code>default via</code> line in <code>ip route show</code> tell you?</summary>

The default gateway: the router the machine sends traffic to when no more specific route matches the destination, and the interface it uses to reach it.
</details>

<details>
<summary>5. You added an address with <code>sudo ip addr add</code>. After a reboot it is gone. Why, and how do you keep it?</summary>

`ip` changes live only in the running kernel. To keep the address, declare it in the network management system's on-disk configuration: a Netplan file under `/etc/netplan/` (then `sudo netplan apply`) or a NetworkManager connection profile.
</details>

<details>
<summary>6. An interface shows an <code>inet6 fe80::…</code> line and nothing else. Is something wrong?</summary>

No. That is the link-local address every IPv6 interface gives itself. It works only on its own segment and does not make the interface reachable from other networks.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy network-interfaces-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-011
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command for its folder, `sections/section-010/module-01/playground`. It always starts clean, so nothing you broke carries over.
