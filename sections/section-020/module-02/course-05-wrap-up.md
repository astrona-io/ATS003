# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the software bridge: a docking hub in the kernel that joins interfaces into one local lane.

**From [A Switch Inside The Kernel](./course-01-a-switch-inside-the-kernel.md):**

- A bridge is a virtual Layer 2 switch. It forwards Ethernet frames between its ports by MAC address.
- The IP address belongs on the bridge, not on a port.
- `ip link` builds the bridge and wires ports (`add name br0 type bridge`, `set <dev> master br0`); `bridge` looks inside it (`bridge link show`, `bridge fdb show`).
- A new bridge starts `DOWN`. A working port shows `master br0` and `state forwarding`.

**From [How A Bridge Learns](./course-02-how-a-bridge-learns.md):**

- The bridge learns source MAC addresses into its forwarding database, forwards to known addresses, and floods unknown and broadcast frames.
- On a quiet segment with one host, the forwarding database holds mostly `permanent` entries.
- When an interface joins a bridge, its address and default route move to the bridge.
- A DHCP client runs on the bridge, never on a port and the bridge at once.

**From [Loops And Spanning Tree](./course-03-loops-and-spanning-tree.md):**

- Two paths between the same places at Layer 2 make a loop, and a loop makes a broadcast storm.
- STP (`stp_state 1`) blocks one port so only one path is active. Turn it on before the second path comes up.
- Take a bridge apart with `nomaster` on each port first, then `ip link delete br0 type bridge`.

**From [Make The Bridge Last](./course-04-make-the-bridge-last.md):**

- A bridge built with `ip` disappears on reboot. A persistent bridge lives in one network-management system.
- A bridge connects segments; a bond merges links. A bond can be a port of a bridge.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Software Bridging Lab](./labs/lab-01/README.md) | Make The Bridge Last | build a bridge and an active-backup bond, and make both persistent |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You created <code>br0</code> and attached a port, but nothing is forwarded. What do you check first?</summary>

Whether `br0` is up. A new bridge starts `state DOWN`. Run `sudo ip link set br0 up`, then check `bridge link show` for `state forwarding`.
</details>

<details>
<summary>2. <code>bridge fdb show br br0</code> shows only <code>permanent</code> entries. Is the bridge broken?</summary>

No. Learned entries need traffic from other hosts. On a quiet segment with one host, `permanent` entries are all you see.
</details>

<details>
<summary>3. Where does the IP address go after you bridge <code>eth3</code>?</summary>

On `br0`. The port only forwards frames at Layer 2; the bridge is the Layer 3 interface the host routes through.
</details>

<details>
<summary>4. You attach two ports that face the same segment, and the network floods. What happened, and what fixes it?</summary>

You built a Layer 2 loop, and broadcasts are storming. Turn on STP with `sudo ip link set dev br0 type bridge stp_state 1`, or bring one port down.
</details>

<details>
<summary>5. After STP settles, one port shows <code>state blocking</code>. Is that a fault?</summary>

No. STP blocks one port on purpose so only one path between the same places is active.
</details>

<details>
<summary>6. What is the difference between a bridge and a bond?</summary>

A bridge connects different segments, like a switch. A bond merges several interfaces into one link for redundancy or more capacity. A bond can itself be a port of a bridge.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy linux-bridging-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-022
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
