# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about Netplan: the YAML flight manual on Ubuntu, and the clerk that turns it into orders for the renderer.

**From [How Netplan Works](./course-01-how-netplan-works.md):**

- Netplan reads YAML files in `/etc/netplan/` and renders configuration for `systemd-networkd` (Ubuntu Server) or `NetworkManager` (Ubuntu Desktop).
- The YAML is declarative: it describes the end result, and Netplan makes the system match.
- `network:` and `version: 2` come first; interfaces sit under a device category such as `ethernets`.
- `netplan get` reads and merges, `generate` translates, `try` applies with an undo, `apply` commits.

**From [Write And Render A Netplan File](./course-02-write-and-render.md):**

- A static interface needs `dhcp4: false` and `addresses` with a prefix on each entry, plus `nameservers` and `routes` as needed.
- Indentation is spaces only, two per level. A tab gives `found character '\t' that cannot start any token`.
- Keep your files at mode `600` and number them high, such as `90-lab.yaml`.
- `netplan generate` writes `systemd-networkd` files under `/run/systemd/network/` without touching the running network.

**From [Apply Safely And Merge Files](./course-03-apply-and-merge.md):**

- `netplan try` applies the change and reverts after 120 seconds unless you press Enter. `netplan apply` has no undo.
- Files merge in filename order, key by key. A later file wins only for the keys it sets.
- `dhcp4: true` with no DHCP (Dynamic Host Configuration Protocol) server leaves the interface in `configuring`.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Private And Public Address Audit Lab](./labs/lab-01/README.md) | Apply Safely And Merge Files | find the private address on the host's interface and the public address seen after NAT |

If you skipped it, go back to it now. It is short, and the exam expects you to read addresses quickly.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which <code>netplan</code> command lets you check a file for errors without changing the network?</summary>

`sudo netplan get`. It parses and merges every file. A broken file makes it print an error instead of the configuration.
</details>

<details>
<summary>2. Your file has <code>addresses: [192.168.1.10]</code>. What is wrong?</summary>

The address has no prefix. Netplan needs it written as `192.168.1.10/24`.
</details>

<details>
<summary>3. You are connected over SSH through the interface you are changing. Which command do you use to apply the change?</summary>

`sudo netplan try`. If the change cuts you off, it reverts on its own after 120 seconds.
</details>

<details>
<summary>4. <code>90-lab.yaml</code> sets an address and DNS servers for <code>enp2s0</code>. <code>99-override.yaml</code> sets only a different address. What does the merged result hold?</summary>

The address from `99-override.yaml` and the DNS (Domain Name System) servers from `90-lab.yaml`. Files merge key by key, and the later file wins only for the keys it sets.
</details>

<details>
<summary>5. You edited a file under <code>/run/systemd/network/</code>, and your change disappeared. Why?</summary>

Netplan generates those files. The next `netplan generate` or `netplan apply` writes them again from the YAML in `/etc/netplan/`.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy netplan-yaml-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-062
```

Then run `astrona list` once more and check that neither name appears any longer.

You can start the playground again at any time with the `astrona run` command for this module's playground. It always starts clean, so nothing you changed carries over.
