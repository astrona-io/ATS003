# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the ship's star chart: the routing table, and the static routes you draw on it by hand.

**From [Read The Star Chart](./course-01-read-the-star-chart.md):**

- A prefix length says how much of an address names the network. A larger number means a smaller, more specific range; `0.0.0.0/0` matches everything.
- The kernel adds a connected route (`proto kernel scope link`) for every addressed interface. It has no gateway.
- `ip route show` prints the table; each line gives the destination, interface, gateway (if any), scope and source address.

**From [Draw A Static Route](./course-02-draw-a-static-route.md):**

- `ip route add <network> via <gateway> dev <interface>` draws a static route. The gateway must be on-link, or you get `Error: Nexthop has invalid gateway`.
- `ip route get <address>` shows which route, interface and source Linux would use. It is a lookup only and sends no packet.
- When several routes match, the longest prefix wins. The default route always loses to a more specific route.

**From [Metrics, Sources And Rules](./course-03-metrics-sources-and-rules.md):**

- The metric orders routes with the same prefix; lower wins. It is not failover on its own.
- Linux uses the selected interface's address as the source, unless a route pins one with `src`.
- `ip route replace` creates or updates a route; `ip route del` may need the same `via`, `dev` and `metric` the route was added with.
- `ip rule show` lists the rules that choose a table: `local`, `main`, `default`.

**From [Test The Path](./course-04-test-the-path.md):**

- `ping -I <interface>` and `ip neigh show` test the next hop. `REACHABLE` with a MAC address means it answered at Layer 2; `FAILED` means it did not.
- `traceroute -n` shows the hops; `*` does not always mean forwarding stopped.
- A conversation needs a return route too. Replies taking another path is asymmetric routing.
- Troubleshoot in order: interface, address, table, route choice, neighbour, ping, trace, return path.

**From [Make Routes Last](./course-05-make-routes-last.md):**

- Routes added with `ip route` disappear on reboot. Persistent routes live in one network-management system, such as a `routes:` list in a Netplan file.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Multi-Interface Static Routing Lab](./labs/lab-01/README.md) | Make Routes Last | add a static route through a gateway, prove it end to end, and make it persistent |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. <code>ip route add 172.16.10.0/24 via 10.0.0.1 dev eth1</code> fails with <code>Nexthop has invalid gateway</code>. Why?</summary>

`10.0.0.1` is not on a network directly attached to `eth1`. The gateway must be on-link. Check `ip addr show dev eth1` and the connected route first.
</details>

<details>
<summary>2. Routes exist for <code>172.16.0.0/16</code> and <code>172.16.100.0/24</code>. Which one does <code>172.16.100.5</code> use?</summary>

The `/24`. Both match, and the longest prefix, the most specific route, wins.
</details>

<details>
<summary>3. <code>ip route get</code> shows a perfect route, but <code>ping</code> gets no reply. Is that possible?</summary>

Yes. `ip route get` is only a table lookup. The next hop may not answer, a firewall may block ICMP, or the far network may have no route back.
</details>

<details>
<summary>4. Two default routes have metrics 100 and 500. Which one is used, and is the other one automatic failover?</summary>

Metric 100 is used. The other is only a standby: Linux must first notice that the preferred route or its interface is gone before it switches.
</details>

<details>
<summary>5. <code>ip neigh show dev eth1</code> shows <code>10.0.0.1 FAILED</code>. What does that tell you?</summary>

The gateway did not answer at Layer 2: nothing replied to the ARP request for `10.0.0.1` on that interface.
</details>

<details>
<summary>6. You added a route with <code>ip route add</code> and rebooted. Where did it go?</summary>

It was runtime state, so the reboot removed it. To keep it, declare it in a network-management system, such as a `routes:` list in a Netplan file.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy static-routing-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-023
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
