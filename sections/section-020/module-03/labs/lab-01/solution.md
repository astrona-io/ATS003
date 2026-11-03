# Solution Walkthrough

You add one static route on `target`, prove it works end to end, then write it into a Netplan file so it survives a reboot.

All commands run on the **`target`** virtual machine (`astrona ssh target` if you are not already on it). You never need to touch `gateway`: its side, the relay ship that forwards traffic, is already set up.

One route, two places:

| Goal | Command or file |
| --- | --- |
| Route **now** (temporary) | `sudo ip route add 10.10.30.0/24 via 10.10.20.1` |
| Route **after reboot** (permanent) | add a `routes:` block to a file under `/etc/netplan/`, then `sudo netplan apply` |

## The feedback loop

Grading runs from your **own terminal**, the shell where you typed `astrona run`, not inside a virtual machine:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-020/module-03/labs/lab-01
```

The `gateway-ready` check runs on the other machine and already passes. The others fail until you do the work:

```text
PASS  gateway-ready
FAIL  route-live
FAIL  route-get
FAIL  route-reachability
FAIL  route-persistent
```

Run it now, and again after each step.

---

## Step 1: Look at what `target` has

On `target`:

```bash
ip -brief addr show
ip route
```

Find the interface that carries `10.10.20.5`: that is the `backend-net` interface. In the examples it is `enp0s2`; yours may be different, so use your own name below. In `ip route` there is **no** line for `10.10.30.0/24` yet. `10.10.20.1` can be reached, because it is on your directly connected `10.10.20.0/24` network.

---

## Step 2: Add the route for right now

```bash
sudo ip route add 10.10.30.0/24 via 10.10.20.1
```

Read this as: "to reach the `10.10.30.0/24` network, hand packets to `10.10.20.1`." Check that it landed:

```bash
ip route show 10.10.30.0/24
ip route get 10.10.30.1
```

The first prints `10.10.30.0/24 via 10.10.20.1 dev enp0s2`. The second, a table lookup for one address, also shows `via 10.10.20.1`.

Now prove it end to end. The gateway forwards, so the address on its far side answers:

```bash
ping -c 3 10.10.30.1
traceroute 10.10.30.1
```

`ping` should get replies, and `traceroute` should show `10.10.20.1` as the first hop.

**Run the check** in your own terminal. `route-live`, `route-get` and `route-reachability` now pass.

---

## Step 3: Make the route persistent

Add the route to a Netplan file for the `backend-net` interface. Do not edit the cloud-init file; add your own.

Save this as `/etc/netplan/99-lab-route.yaml` on `target` (for example with `sudo nano /etc/netplan/99-lab-route.yaml`), replacing `enp0s2` with your `backend-net` interface name:

```yaml
network:
  version: 2
  ethernets:
    enp0s2:
      routes:
        - to: 10.10.30.0/24
          via: 10.10.20.1
```

- `routes:` is a list of static routes for that interface.
- `to:` is the destination network, and `via:` is the next-hop gateway: the same two values you used with `ip route add`.

Apply it:

```bash
sudo chmod 600 /etc/netplan/99-lab-route.yaml
sudo netplan apply
```

Then check the result. The route is still there:

```bash
ip route show 10.10.30.0/24
```

**Run the check.** `route-persistent` now passes. Everything is green.

---

## Step 4: Submit

When `astrona submit` shows every line as `PASS`:

```text
PASS  gateway-ready
PASS  route-live
PASS  route-get
PASS  route-reachability
PASS  route-persistent
```

Submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-020/module-03/labs/lab-01
```

---

## If a check stays red

- **`ip route add` fails with "Nexthop has invalid gateway".** `10.10.20.1` is not on a directly connected network where you ran the command. Make sure you are on **`target`** (not `gateway`), and that its `backend-net` interface is up with `10.10.20.5`.
- **`route-live` and `route-get` pass, but `route-reachability` fails.** The route points the wrong way or at the wrong gateway. Check that it reads `via 10.10.20.1`, and that `ping 10.10.20.1` (the next hop itself) works.
- **`route-persistent` fails.** The check needs both `10.10.30.0` and `10.10.20.1` in the same persistent file. Check that your Netplan file name ends in `.yaml`, the `to:` and `via:` values are exact, and you saved it.
