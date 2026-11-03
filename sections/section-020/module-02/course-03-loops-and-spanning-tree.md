# Loops And Spanning Tree

Astronaut, two docking hubs linked twice can trap a signal in an endless circle. Each lap copies it again, until the communications array drowns in its own echoes. In this part you build that loop on purpose, watch the **Spanning Tree Protocol** stop it, and then take the bridge apart cleanly.

## How a loop forms

A loop needs two paths between the same places at Layer 2. It is easy to build one by accident, and the effect is fast and loud.

### The broadcast storm

Connecting two bridges twice, or attaching two ports of one bridge to the same segment, creates a **Layer 2 loop**. Frames then go round and round, and broadcasts multiply until they fill the network. This is a **broadcast storm**. You see duplicate frames, MAC addresses jumping between ports, high processor load, and lost connections.

## Spanning Tree Protocol

The **Spanning Tree Protocol (STP)** finds redundant Layer 2 paths and puts chosen ports into a `blocking` state, so exactly one path stays active. The bridge runs it in the kernel; you only switch it on or off.

### Turning STP on and off

Toggle it per bridge:

```bash
sudo ip link set dev br0 type bridge stp_state 1   # on
sudo ip link set dev br0 type bridge stp_state 0   # off
```

A bridge with one physical and one virtual port has no second path and does not need STP. More complex layouts do.

### See it in your playground

<!-- astrona:playground:renew -->

You need `br0`, up, with one spare interface (here `enp0s2`) attached and up. Both spare interfaces face the **same** segment, so attaching the second one as well makes a loop on purpose. Turn STP on **before** the second port comes up, so the loop is managed from the start instead of storming first:

```sh
sudo ip link set dev br0 type bridge stp_state 1
sudo ip link set enp0s3 master br0
sudo ip link set enp0s3 up
bridge link show
```

Give STP's default timers about 30 seconds to settle, then run `bridge link show` again. Expect something like:

```text
3: enp0s2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 100
4: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state blocking priority 32 cost 100
```

One port is `forwarding`, the other is `blocking`. STP kept the segment reachable while it broke the loop. `ip -d link show dev br0` shows `stp_state 1`.

Setting `stp_state 0` returns both ports to `forwarding`, and the loop goes live. Broadcast traffic then climbs, so turn STP back on, or run `sudo ip link set enp0s3 down` to calm it. The names, priority and cost are examples.

> [!TIP]
> When a new port sits in `listening` or `learning` for a while, STP is doing its start-up checks. Wait about 15 to 30 seconds before you decide the bridge is broken.

## Removing a port and deleting the bridge

Take a bridge apart in the reverse order you built it: detach the ports first, then delete the bridge.

### The commands

Detach a port with `nomaster`, then delete the bridge once no ports remain:

```bash
sudo ip link set enp0s3 down
sudo ip link set enp0s3 nomaster
sudo ip link delete br0 type bridge
```

Deleting the bridge removes its runtime configuration and cuts off anything that was using it.

## Common pitfalls

> [!WARNING]
> - **Bridging two ports onto the same segment with STP off.** That is a loop. Broadcast frames storm within seconds. Turn on `stp_state 1` first, or keep the second port down.
> - **Reading `blocking` as a fault.** A blocking port in a looped layout is STP doing its job.
> - **Deleting a bridge with ports still attached.** Detach each port with `nomaster` first, then run `ip link delete br0`.
