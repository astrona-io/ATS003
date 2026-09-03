# Solution Walkthrough

You will find two addresses and write each one to a file. Everything runs on
the VM's `terminal`.

Two addresses, two ways to find them:

| Address | What it is | How to find it |
| --- | --- | --- |
| Private IPv4 | the address on your own interface | `ip -4 addr show` (or `hostname -I`) |
| Public IPv4 | the address the internet sees you as | ask an outside service: `curl ifconfig.me` or `dig … myip.opendns.com` |

The target directory `/opt/course` already exists and your user can write to
it — no `sudo` needed for the file writes.

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`, not inside the VM:

```bash
astrona test -c labs/section-060/module-02/lab-01
```

Two checks:

```text
FAIL  private-ip
FAIL  public-ip
```

Run it now, then again after each step.

---

## Step 1: Find and record the private address

On the VM, list the IPv4 addresses on your interfaces:

```bash
ip -4 addr show
```

Ignore `127.0.0.1` (that is loopback). The other address is your private
address — it will look like `10.0.2.15`, `172.20.x.x`, or `192.168.x.x`.
There is a shorter way to print just the real addresses:

```bash
hostname -I
```

Take that address **without** the `/24` (or other) prefix and write it to
the file:

```bash
echo 10.0.2.15 > /opt/course/private_ip
```

Replace `10.0.2.15` with the address you actually saw. Check what you wrote:

```bash
cat /opt/course/private_ip
```

**Run the check** on the host terminal — `private-ip` now passes.

---

## Step 2: Find and record the public address

Your host sits behind NAT, so its own interface does not know the public
address. You have to ask a server on the outside what address your traffic
arrives from. Two independent ways — use whichever answers:

HTTP method:

```bash
curl -s ifconfig.me
```

(If that hangs or is blocked, try `curl -s https://icanhazip.com`.)

DNS method:

```bash
dig -4 +short myip.opendns.com @resolver1.opendns.com
```

Both print a single public IPv4 address such as `203.0.113.47`. Write it to
the file:

```bash
echo 203.0.113.47 > /opt/course/public_ip
```

Replace it with your actual address. Check:

```bash
cat /opt/course/public_ip
```

**Run the check** — `public-ip` now passes. Both green.

---

## Step 3: Submit

When `astrona test` shows both `PASS`:

```text
PASS  private-ip
PASS  public-ip
```

Submit from the host terminal:

```bash
astrona submit -c labs/section-060/module-02/lab-01
```

---

## If a check stays red

- **`private-ip` fails.** You wrote the loopback address `127.0.0.1`, or you
  left the `/24` prefix on the address, or there is extra text in the file.
  The file must hold exactly one bare address that `hostname -I` also shows.
- **`public-ip` fails, "not a valid IPv4 address".** `curl` returned an
  error page or HTML instead of an address, or nothing at all. Try the other
  method (DNS instead of HTTP, or vice versa) and re-check the file with
  `cat`.
- **`public-ip` fails, "looks like a private address".** You accidentally
  wrote your private address into `public_ip`. The two files hold different
  addresses.
