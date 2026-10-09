# Solution Walkthrough

You will find two addresses and write each one to a file. Everything runs on
the lab virtual machine's `terminal`, except grading.

There are two addresses, and two ways to find them:

| Address | What it is | How to find it |
| --- | --- | --- |
| Private IPv4 | the address on your own interface | `ip -4 addr show` (or `hostname -I`) |
| Public IPv4 | the address the internet sees you as | ask an outside service: `curl ifconfig.me` or `dig … myip.opendns.com` |

The target directory `/opt/course` already exists, and your user can write
to it. You do not need `sudo` to write the files.

## The feedback loop

Grading runs from your **own terminal**: the shell where you typed
`astrona run`, not inside the virtual machine:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-01/labs/lab-01
```

There are two checks:

```text
FAIL  private-ip
FAIL  public-ip
```

Run it now, then again after each step.

---

## Step 1: Find and record the private address

On the virtual machine, list the IPv4 addresses on your interfaces:

```bash
ip -4 addr show
```

Ignore `127.0.0.1`: that is loopback, the machine's internal intercom. The
other address is your private address. It looks like `10.0.2.15`,
`172.20.x.x` or `192.168.x.x`. A shorter command prints just the real
addresses:

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

**Run the check** from your own terminal. `private-ip` now passes.

---

## Step 2: Find and record the public address

Your host sits behind NAT, so its own interface does not know the public
address. You have to ask a server outside which address your traffic arrives
from. There are two independent ways; use whichever answers.

The HTTP way:

```bash
curl -s ifconfig.me
```

If that hangs or is blocked, try `curl -s https://icanhazip.com`.

The DNS way:

```bash
dig -4 +short myip.opendns.com @resolver1.opendns.com
```

Both print a single public IPv4 address, such as `203.0.113.47`. Write it to
the file:

```bash
echo 203.0.113.47 > /opt/course/public_ip
```

Replace it with your actual address. Check:

```bash
cat /opt/course/public_ip
```

**Run the check**. `public-ip` now passes, and both checks are green.

---

## Step 3: Submit

When `astrona submit` shows both as `PASS`:

```text
PASS  private-ip
PASS  public-ip
```

Submit from your own terminal:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-01/labs/lab-01
```

---

## If a check stays red

- **`private-ip` fails.** You wrote the loopback address `127.0.0.1`, left
  the `/24` prefix on the address, or put extra text in the file. The file
  must hold exactly one bare private address that `hostname -I` also shows.
- **`public-ip` fails with "not a valid IPv4 address".** `curl` returned an
  error page, HTML or nothing at all instead of an address. Try the other
  way (DNS instead of HTTP, or the other way round) and check the file again
  with `cat`.
- **`public-ip` fails with "looks like a private address".** You wrote your
  private address into `public_ip` by mistake. The two files hold different
  addresses.
