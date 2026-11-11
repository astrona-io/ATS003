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

Netplan merges mappings from its YAML files. A later scalar value, such as `dhcp4`, replaces an earlier scalar. Sequences, including `addresses`, are combined. A later address list does not remove an earlier address.

Suppose `/etc/netplan/90-lab.yaml` gives the spare interface `192.168.130.50/24`. This additional file, `/etc/netplan/99-extra.yaml`, adds a second address:

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      addresses: [192.168.130.60/24]
```

After saving it with mode `600`, inspect the merged configuration before applying it:

```bash
sudo chmod 600 /etc/netplan/99-extra.yaml
sudo netplan get ethernets.enp2s0
sudo netplan generate
```

The merged `addresses` list contains both `.50/24` and `.60/24`. `generate` validates and renders the configuration; it does not apply it to the running interface. To keep only the original address, remove the extra declaration or rename that file so it no longer ends in `.yaml`:

```bash
sudo mv /etc/netplan/99-extra.yaml /etc/netplan/99-extra.yaml.disabled
sudo netplan generate
sudo netplan apply
ip -br address show enp2s0
```

Use your playground's spare interface name. Inspect both `netplan get` and `ip address`: a live deletion alone will be undone at the next apply or reboot. See the [Netplan configuration reference](https://netplan.readthedocs.io/en/stable/netplan-yaml/).

## Common pitfalls

> [!WARNING]
> - **`netplan apply` on a remote machine.** There is no automatic revert. Use `netplan try` for anything touching the interface you are connected through.
> - **File-order surprises.** `50-cloud-init.yaml` can override a lower-numbered file you wrote. Use a higher number and confirm with `netplan get`.
> - **`dhcp4: true` with no DHCP server.** The interface sits in `configuring` and never gets an address.

## Practice: Repair merged Netplan configuration

Trace an unexpected address to a second Netplan file. Correct the merged configuration and apply it. Verify the sole intended address after reboot. This lab starts independently; changes in the playground do not carry over.

Pause the playground first:

```bash
astrona stop netplan-yaml-playground
```

Read the [task](labs/lab-01/question.md), then start the lab:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-02/labs/lab-01
```

Use the inspection commands while working. Submit once all tasks are complete; submission ends the environment.

Resume the playground afterwards:

```bash
astrona start netplan-yaml-playground
```
