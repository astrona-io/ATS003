# Apply Safely And Merge Files

Astronaut, a flight manual only matters once the crew follows it. In this part you make your Netplan file live with a safety timer, then add a second file and see exactly which settings it overrides.

The steps below need the file `/etc/netplan/90-lab.yaml` that gives your spare interface the address `192.168.130.50/24` and the DNS server `192.168.130.1`, with mode `600`.

## Applying safely: `netplan try`

`netplan apply` renders the configuration and tells the backend to adopt it, live. On a remote machine a mistake (a wrong address, a broken default route) can cut your connection to mission control with nothing to undo it.

### The safety timer

`netplan try` is the safe form. It applies the configuration, then starts a **120-second countdown**. Press Enter to keep the change. Do nothing and it **reverts** to the previous configuration on its own. Use it for every change to an interface you depend on.

### Apply with the safety timer

<!-- astrona:playground:renew -->

Apply the `/etc/netplan/90-lab.yaml` file that describes your spare interface:

```sh
sudo netplan try
```

Expect the configuration to apply and a prompt to appear:

```text
Warning: Stopping systemd-networkd.service, but it can still be activated by:
  systemd-networkd.socket
Do you want to keep these settings?

Press ENTER before the timeout to accept the new configuration

Changes will revert in 120 seconds
```

Press Enter to keep it, then check the interface:

```sh
ip -brief addr show enp2s0
networkctl status enp2s0
```

```text
enp2s0   UP   192.168.130.50/24
```

The address is live and on disk. `sudo netplan apply` does the same thing **without** the timer. That is fine on the console or for an interface you are not connected through, and risky otherwise.

## How multiple files merge

Netplan reads every `*.yaml` in `/etc/netplan/` in filename order and merges them **key by key**. This is why the number at the front of a file name matters.

### Later files win, one key at a time

When two files set the same leaf key, the one that sorts **later** wins. That is why cloud-init uses `50-` and you use higher numbers to override it.

It is not whole-file replacement. A `99-` file that sets only `addresses` for an interface leaves that interface's `routes` from a `50-` file in place.

### A later file overrides one key

Save this as `/etc/netplan/99-override.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      addresses:
        - 192.168.130.60/24
```

Set its permissions and read the merged result for the interface:

```sh
sudo chmod 600 /etc/netplan/99-override.yaml
sudo netplan get ethernets.enp2s0
```

Expect the address from `99-` and the `nameservers` still from `90-`:

```text
addresses:
- 192.168.130.60/24
dhcp4: false
nameservers:
  addresses:
  - 192.168.130.1
```

`99-override.yaml` won for `addresses` only. Everything it did not mention came through from `90-lab.yaml`. Delete the override file when you are done, so the picture stays simple.

## Common pitfalls

> [!WARNING]
> - **`netplan apply` on a remote machine.** There is no automatic revert. Use `netplan try` for anything touching the interface you are connected through.
> - **File-order surprises.** `50-cloud-init.yaml` can override a lower-numbered file you wrote. Use a higher number and confirm with `netplan get`.
> - **`dhcp4: true` with no DHCP server.** The interface sits in `configuring` and never gets an address.

## Your mission: Private And Public Address Audit Lab

You can now write, check and apply the file that gives an interface its address. The graded mission does not ask for a Netplan file: it asks for an address audit. You find the private address the host's own interface carries and the public address the internet sees after NAT (network address translation, the relay station that swaps your call sign for its own), and write each one to a file.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop netplan-yaml-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-02/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/module-02/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-062
astrona start netplan-yaml-playground
```
