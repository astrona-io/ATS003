# Netfilter And The Packet Path

Astronaut, before you program the shields, you need to know where on the hull they stand. A rule that filters "incoming" traffic never sees a packet that is only passing through. A rule at the wrong priority runs after the address has already been rewritten.

This part is the map. It shows the fixed points a packet passes, the order it passes them in, and where an nftables chain plugs in.

## Netfilter is older and bigger than nftables

nftables is not the shield generator itself. It is one of several tools that program it. This section explains what the generator does on its own, so the rest of the module makes sense.

### The shield generator in the kernel

**Netfilter** is a framework built into the Linux kernel's network code. At five fixed points on a packet's journey, it stops and calls a list of registered **callbacks** (small pieces of code), in priority order. Each callback returns a **verdict**: keep going, drop, take the packet away, or queue it for a program outside the kernel. That is the whole mechanism.

nftables is *one* user of that framework. So are the old `iptables` commands (through a compatibility layer), the connection tracker, the address-rewriting engine and packet loggers. When you add an nftables base chain, you register one more callback on one of those five points.

Picture the generator as a ring of five checkpoints around the ship's hull. nftables is one guard you post at a checkpoint. Signals pass the checkpoints whether or not a guard stands there; an empty checkpoint simply waves everything through.

### The five hooks

The five points are called **hooks**. For IPv4 and IPv6 they are:

| Hook | A packet reaches it when… |
|---|---|
| `prerouting` | it has just arrived on an interface, **before** the kernel decides where it is going |
| `input` | routing decided the packet is **for this host** |
| `forward` | routing decided the packet is **passing through** to another host |
| `output` | a local process just sent it, before routing |
| `postrouting` | it is about to leave on an interface, **after** all routing and address decisions |

## The routing decision splits the paths

Which hook sees a packet depends on one decision the kernel makes early on. Learn this decision, and choosing the right hook becomes easy.

### One question: for me, or for someone else?

The kernel makes its **routing decision** once, right after `prerouting`. It looks at the destination address and answers one question: *is this packet for me, or for somewhere else?* That answer sends the packet down the `input` path or the `forward` path.

Nothing in a `forward` chain can touch a packet bound for a local program, and nothing in an `input` chain can touch traffic that is only passing through. Choosing the hook **is** choosing the kind of traffic.

```text
                              +--> INPUT --> (local socket / process)
   NIC --> PREROUTING --> [routing]
                              +--> FORWARD --> POSTROUTING --> NIC (out)

   (local process) --> OUTPUT --> [routing] --> POSTROUTING --> NIC (out)
```

In the drawing, NIC means network interface card, one antenna on the ship's communications array. A socket is the open radio channel a program listens on.

### The three routes

Read the drawing as three routes:

- **Inbound to this host:** `prerouting`, then routing, then `input`, then delivery to a socket.
- **Passing through (this host acts as a router):** `prerouting`, then routing, then `forward`, then `postrouting`, then out. This needs `net.ipv4.ip_forward=1`; without it, the kernel drops the packet after routing.
- **Sent by this host:** socket, then `output`, then routing, then `postrouting`, then out. Replies your server sends to a client take this route. That is why locking down `input` without thinking about `output` still lets the machine talk out.

For a plain server that only protects itself, **`input` is the hook that matters**. `forward` matters as soon as the machine routes traffic for others, for example for a container bridge, a virtual private network (VPN) or a gateway.

## Hooks run callbacks in priority order

Several parts of the kernel want the same hook. Connection tracking, address rewriting, your filter rules and a packet logger might all sit on `prerouting`. This section shows how netfilter decides who goes first.

### Priority is a signed number

Netfilter runs the callbacks on a hook **lowest priority number first**. Priority is a **signed whole number**: negative numbers run early and positive numbers run late. So a new piece of the kernel can always slot in before or after an existing one.

nftables gives the common priority values keyword names. You can write the number or the keyword; `nft` prints the keyword back.

| Keyword | Number | What usually lives here |
|---|---:|---|
| `raw` | -300 | rules that take packets **out** of connection tracking (`notrack`) |
| `mangle` | -150 | early header edits (time to live, type of service, packet marks) |
| `dstnat` | -100 | destination address rewriting and port forwarding (`prerouting` only) |
| `filter` | 0 | ordinary accept and drop filtering, **the default for a filter chain** |
| `security` | 50 | SELinux and `secmark` labels |
| `srcnat` | 100 | source address rewriting and masquerade (`postrouting` only) |

### Where connection tracking sits

Connection tracking, the shield's memory of conversations already in progress, registers at priority **-200** on `prerouting` and `output`, and again near the end to confirm the connection. So it is safe to write `ct state` matches in a `filter` (0) chain: the tracker has already run and stamped the packet by the time your chain sees it.

Two base chains on the *same* hook run in priority order. A final verdict in the earlier chain wins, and the later chain never sees that packet. Two chains with the *same* priority on the same hook are allowed, but the order between them is not defined, so do not rely on it.

## See a chain on a hook

Now watch the routing decision at work on your playground. You put a counting rule on two different hooks and send the same traffic each time.

### Count packets on the input hook

<!-- astrona:playground:renew -->

Create a table, put a chain on the `input` hook, add a rule that only counts, and send three pings to your own ship:

```sh
sudo nft add table inet demo
sudo nft 'add chain inet demo watch { type filter hook input priority 0 ; policy accept ; }'
sudo nft add rule inet demo watch counter
ping -c 3 127.0.0.1 >/dev/null
sudo nft list chain inet demo watch
```

The bare `counter` rule shows a packet count above zero:

```text
table inet demo {
	chain watch {
		type filter hook input priority filter; policy accept;
		counter packets 6 bytes 504
	}
}
```

Every packet that the routing decision sent to `input` crossed your chain. `policy accept` and a rule with no verdict mean nothing was blocked; the chain only *watched*.

### Count packets on the forward hook

Now put the same counter on the `forward` hook and send the same pings:

```sh
sudo nft 'add chain inet demo transit { type filter hook forward priority 0 ; policy accept ; }'
sudo nft add rule inet demo transit counter
ping -c 3 127.0.0.1 >/dev/null
sudo nft list chain inet demo transit
```

The `forward` chain's counter stays at **zero**. Loopback traffic (the ship's internal intercom) is meant for this host, so the kernel's routing decision sent it to `input` and never to `forward`.

Clean up when you are done:

```sh
sudo nft delete table inet demo
```

> [!TIP]
> When a rule "does nothing", first ask which hook the packet really passes. A bare `counter` rule on the chain answers that in seconds.

## Common pitfalls

> [!WARNING]
> - **Filtering passing-through traffic in `input`.** A packet for another host never reaches `input`. It goes through `forward`.
> - **Locking down `input` and forgetting `output`.** Packets your own programs send take the `output` path, so an `input` rule never stops them.
> - **Relying on two chains with the same priority.** Their order on a hook is not defined. Give them different priorities.

> *A base chain only ever sees the kind of traffic its hook stands for, and it runs at a fixed spot in a priority-ordered line of kernel callbacks. Pick the hook for the traffic, and the priority for the order.*
