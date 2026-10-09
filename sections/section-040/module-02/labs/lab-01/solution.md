# Solution Walkthrough

Two machines, one job each: turn `server` into an NTP (Network Time Protocol) server with one configuration line, and point `client` at it. chrony is each ship's clockmaster; `allow` lets other ships set their clocks from yours. Open a shell on each machine with `astrona ssh server` and `astrona ssh client`.

| Machine | Change | File |
| --- | --- | --- |
| `server` | add `allow 192.168.10.0/24` | `/etc/chrony/chrony.conf` |
| `client` | replace public sources with `server astrona-ats-003-lab-042-server iburst` | `/etc/chrony/chrony.conf` |
| both | `sudo systemctl restart chrony` after editing | — |

If `astrona list` on the host shows the server machine under a different name, use that name in place of `astrona-ats-003-lab-042-server` below.

## The feedback loop

Grading runs from the **host terminal**, the shell where you typed `astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-02/labs/lab-01
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

## Step 1: On `server`, allow the subnet

Open the configuration file on `server`:

```bash
astrona ssh server
sudo nano /etc/chrony/chrony.conf
```

Add this line. Type it exactly: the check matches the whole line.

```text
allow 192.168.10.0/24
```

That single directive is what changes `chronyd` from "client only" to "also answers queries from that subnet". Save and exit, then apply it:

```bash
sudo systemctl restart chrony
```

Then check the server side:

```bash
sudo ss -ulnp | grep :123
chronyc serverstats
chronyc tracking
```

You want a listener on `:123`, `serverstats` printing `NTP packets received`, and `tracking` showing `Leap status : Normal`.

**Run the check.** `allow-directive`, `listening-udp123` and `serverstats` pass now. `tracking-synced` passes once the server has locked onto its own upstream sources (it may already be done).

---

## Step 2: On `client`, use the internal server

Open the configuration file on `client`:

```bash
astrona ssh client
sudo nano /etc/chrony/chrony.conf
```

Comment out (`#`) every existing `pool ` and `server ` line, then add one line:

```text
server astrona-ats-003-lab-042-server iburst
```

Save and exit, then apply it:

```bash
sudo systemctl restart chrony
```

**Run the check.** `client-points-at-server` passes straight away.

---

## Step 3: On `client`, confirm it syncs through the server

Give it up to a minute, then:

```bash
chronyc sources -v
chronyc tracking
```

In `chronyc sources`, the line for `astrona-ats-003-lab-042-server` should start with `^*` (the caret means a server source, the star means selected). `chronyc tracking` should show `Leap status : Normal` and a `Stratum` value one higher than the server's. If it is still `^?` or `^~`, wait and check again, or give it a nudge: `sudo chronyc burst 4/4`, then `chronyc sources` again.

**Run the check.** `client-synced-via-server` now passes. All six are green.

---

## Step 4: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-02/labs/lab-01
```

---

## If a check stays red

- **`allow-directive` fails.** The line must be exactly `allow 192.168.10.0/24` and not commented out. Check the spacing and the `#`.
- **`listening-udp123` fails.** chrony was not restarted after you added `allow`, or `allow` is missing. Run `sudo systemctl restart chrony`.
- **`client-points-at-server` fails.** A public `pool` or `server` line is still active in the client's configuration file. Comment out *every* one; only the `server astrona-ats-003-lab-042-server` line stays.
- **`client-synced-via-server` fails.** Give it more time, or run `sudo chronyc burst 4/4` on the client. Also confirm that `chronyc tracking` on `server` already shows `Normal`: a server that is not itself synced cannot sync the client.
