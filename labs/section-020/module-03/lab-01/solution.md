# Solution Walkthrough

You will add one static route on `target`, prove it works end to end, then
write it into a config file so it survives a reboot.

All commands run on the **`target`** VM (`astrona ssh target` if you are not
already on it). You never need to touch `gateway` — its side is already set
up.

One route, two places:

| Goal | Command / file |
| --- | --- |
| Route **now** (temporary) | `sudo ip route add 10.10.30.0/24 via 10.10.20.1` |
| Route **after reboot** (permanent) | add a `routes:` block to a `/etc/netplan/` file, then `sudo netplan apply` |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside a VM:

```bash
astrona test -c labs/section-020/module-03/lab-01
```

Checks (the `gateway-ready` one runs on the other VM and already passes):

```text
PASS  gateway-ready
FAIL  route-live
FAIL  route-get
FAIL  route-reachability
FAIL  route-persistent
```

Run it now, then again after each step.

---

## Step 1: Look at what `target` has

On `target`:

```bash
ip -brief addr show
ip route
```

Find the interface that carries `10.10.20.5` — that is the `backend-net`
NIC. In the examples it is `enp0s2` (yours may differ; use your own name
below). In `ip route` there is **no** line for `10.10.30.0/24` yet, and
`10.10.20.1` is reachable because it is on your directly connected
`10.10.20.0/24` network.

---

## Step 2: Add the route for right now

```bash
sudo ip route add 10.10.30.0/24 via 10.10.20.1
```

Read this as: "to reach the `10.10.30.0/24` network, hand packets to
`10.10.20.1`." Check it landed:

```bash
ip route show 10.10.30.0/24
ip route get 10.10.30.1
```

The first prints `10.10.30.0/24 via 10.10.20.1 dev enp0s2`. The second, a
table lookup for one address, also shows `via 10.10.20.1`.

Now prove it end to end — the gateway forwards, so its far-side address
answers:

```bash
ping -c 3 10.10.30.1
traceroute 10.10.30.1
```

`ping` should get replies; `traceroute` should show `10.10.20.1` as the
first hop.

**Run the check** on the host terminal — `route-live`, `route-get`, and
`route-reachability` now pass.

---

## Step 3: Make the route persistent

Add the route to a Netplan file for the `backend-net` interface. Do not edit
the cloud-init file — add your own. On `target`:

```bash
sudo nano /etc/netplan/99-lab-route.yaml
```

Type this in, replacing `enp0s2` with your `backend-net` interface name:

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
- `to:` is the destination network, `via:` is the next-hop gateway — the
  same two values you used with `ip route add`.

Save and exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`), then:

```bash
sudo chmod 600 /etc/netplan/99-lab-route.yaml
sudo netplan apply
```

Confirm the route is still there:

```bash
ip route show 10.10.30.0/24
```

**Run the check** — `route-persistent` now passes. All green.

---

## Step 4: Submit

When `astrona test` shows every line `PASS`:

```text
PASS  gateway-ready
PASS  route-live
PASS  route-get
PASS  route-reachability
PASS  route-persistent
```

Submit from the host terminal:

```bash
astrona submit -c labs/section-020/module-03/lab-01
```

---

## If a check stays red

- **`ip route add` fails, "Nexthop has invalid gateway".** `10.10.20.1` is
  not on a directly connected network from where you ran the command. Make
  sure you are on **`target`** (not `gateway`) and that its `backend-net`
  NIC is up with `10.10.20.5`.
- **`route-live` / `route-get` pass but `route-reachability` fails.** The
  route points somewhere wrong, or at the wrong gateway. Re-check it reads
  `via 10.10.20.1`, and that `ping 10.10.20.1` (the next hop itself) works.
- **`route-persistent` fails.** The check needs both `10.10.30.0` and
  `10.10.20.1` in the same persistent file. Confirm your Netplan file is
  named `*.yaml`, the `to:`/`via:` values are exact, and you saved it.
