# Solution Walkthrough

Two machines, one job each: turn `server` into an NTP server with one
config line, and repoint `client` at it. Open a shell on each with
`astrona ssh server` and `astrona ssh client`.

| Machine | Change | File |
| --- | --- | --- |
| `server` | add `allow 192.168.10.0/24` | `/etc/chrony/chrony.conf` |
| `client` | replace public sources with `server astrona-ats-003-lab-042-server iburst` | `/etc/chrony/chrony.conf` |
| both | `sudo systemctl restart chrony` after editing | — |

> If `astrona list` on the host shows the server VM under a different name,
> use that name in place of `astrona-ats-003-lab-042-server` below.

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`:

```bash
astrona test -c labs/section-040/module-02/lab-01
```

Six checks (four on `server`, two on `client`):

```text
FAIL  allow-directive
FAIL  listening-udp123
FAIL  serverstats
FAIL  tracking-synced
FAIL  client-points-at-server
FAIL  client-synced-via-server
```

Run it after each step.

---

## Step 1: On `server` — allow the subnet

```bash
astrona ssh server
sudo nano /etc/chrony/chrony.conf
```

Add this line (exactly — the check matches it precisely):

```text
allow 192.168.10.0/24
```

That single directive is what flips `chronyd` from "client only" to "also
answers queries from that subnet". Save and exit, then restart:

```bash
sudo systemctl restart chrony
```

Check the server side:

```bash
sudo ss -ulnp | grep :123
chronyc serverstats
chronyc tracking
```

You want a listener on `:123`, `serverstats` printing `NTP packets
received`, and `tracking` showing `Leap status : Normal`.

**Run the check** — `allow-directive`, `listening-udp123`, `serverstats`
pass now; `tracking-synced` passes once the server has locked onto its own
upstream sources (may already be done).

---

## Step 2: On `client` — use the internal server

```bash
astrona ssh client
sudo nano /etc/chrony/chrony.conf
```

Comment out (`#`) every existing `pool ` and `server ` line, then add one:

```text
server astrona-ats-003-lab-042-server iburst
```

Save and exit, then restart:

```bash
sudo systemctl restart chrony
```

**Run the check** — `client-points-at-server` passes immediately.

---

## Step 3: On `client` — confirm it syncs through the server

Give it up to a minute, then:

```bash
chronyc sources -v
chronyc tracking
```

In `chronyc sources` the line for `astrona-ats-003-lab-042-server` should
start with `^*` (caret = server source, star = selected). `chronyc
tracking` should show `Leap status : Normal` and a `Stratum` value one
higher than the server's. If it is still `^?` or `^~`, wait and re-check, or
nudge it: `sudo chronyc burst 4/4` then `chronyc sources` again.

**Run the check** — `client-synced-via-server` now passes. All six green.

---

## Step 4: Submit

```bash
astrona submit -c labs/section-040/module-02/lab-01
```

---

## If a check stays red

- **`allow-directive` fails.** The line must be exactly
  `allow 192.168.10.0/24` and not commented. Re-check spacing and the `#`.
- **`listening-udp123` fails.** chrony was not restarted after adding
  `allow`, or `allow` is missing. `sudo systemctl restart chrony`.
- **`client-points-at-server` fails.** A public `pool`/`server` line is
  still active in the client's config. Comment out *every* one; only the
  `server astrona-ats-003-lab-042-server` line stays.
- **`client-synced-via-server` fails.** Give it more time, or run
  `sudo chronyc burst 4/4` on the client. Also confirm `chronyc tracking`
  on `server` is already `Normal` — a server that is not itself synced
  cannot sync the client.
