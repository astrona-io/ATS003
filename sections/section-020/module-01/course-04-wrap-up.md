# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about bonding: teaming several antennas into one link, `bond0`, so the ship stays connected when one of them fails.

**From [One Link From Many Antennas](./course-01-one-link-from-many.md):**

- A bond presents several member interfaces as one logical interface, `bond0`. It is kernel software, not a physical port.
- The IP address and any route go on `bond0`. The members carry frames at Layer 2.
- `ip link add bond0 type bond mode active-backup miimon 100` creates the bond. Each member must be `DOWN` before `ip link set <dev> master bond0` accepts it.
- `cat /proc/net/bonding/bond0` shows the live mode, the active member and each member's link state.

**From [Bonding Modes And Failover](./course-02-modes-and-failover.md):**

- Mode 1 (`active-backup`) gives failover only and needs nothing from the switch. Mode 5 (`balance-tlb`) spreads outgoing traffic. Mode 4 (`802.3ad`) needs a matching LACP group on the switch.
- A single flow always stays on one member, whatever the mode.
- `miimon` checks the local link every given number of milliseconds. It does not prove a gateway or remote host can be reached.
- Taking the active member down moves `Currently Active Slave` to the other member and raises the `Link Failure Count`.

**From [Make The Bond Last](./course-03-make-the-bond-last.md):**

- A bond built with `ip` is runtime state and disappears on reboot.
- A persistent bond lives in one network-management system, such as Netplan or NetworkManager, never in two at once.
- Real redundancy also needs separate cables, switch ports, switches, power and paths beyond the switch.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Link Aggregation (Bonding) Lab](./labs/lab-01/README.md) | Make The Bond Last | build an active-backup bond and a bridge, and make both persistent |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You bond two 1 Gbit/s interfaces in mode 1. How much bandwidth do you get?</summary>

About 1 Gbit/s. Active-backup uses one member at a time; the other only waits to take over.
</details>

<details>
<summary>2. <code>ip link set enp0s2 master bond0</code> fails. What is the most likely cause?</summary>

`enp0s2` is still `UP`. The kernel only moves an interface into a bond when it is `DOWN`. Bring it down, attach it, then bring it and the bond up.
</details>

<details>
<summary>3. Every member shows <code>MII Status: up</code>, but you cannot reach the gateway. Is the bond broken?</summary>

Not necessarily. MII monitoring only checks the local link. A failure further along, such as a dead router, does not change the members' link state.
</details>

<details>
<summary>4. Which mode needs configuration on the switch?</summary>

Mode 4, `802.3ad`. The switch ports must be in the same LACP group, or the group never forms.
</details>

<details>
<summary>5. Where does the IP address go: on <code>bond0</code> or on a member?</summary>

On `bond0`. The bond is the interface the operating system routes through; the members carry frames for it at Layer 2.
</details>

<details>
<summary>6. You reboot and <code>/proc/net/bonding/bond0</code> is gone. What went wrong?</summary>

Nothing went wrong: the bond was built with `ip`, which is runtime state only. To keep it, declare it in Netplan or NetworkManager.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy linux-bonding-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-021
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
