# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module and its mission. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about firewalld: shield presets (zones) and named bundles of ports (services), written as nftables rules for you.

**From [Architecture And The nftables Backend](./course-01-architecture-and-backends.md):**

- firewalld is a daemon (`firewalld.service`) that owns the ruleset; `firewall-cmd` only sends it requests over D-Bus.
- Stock definitions live in `/usr/lib/firewalld/` (never edit); your changes live in `/etc/firewalld/`.
- "Dynamic" means changes splice in without a flush, so live connections survive. `--reload` keeps connection tracking state; `--complete-reload` drops it.
- Underneath, firewalld writes `table inet firewalld`. On a firewalld host, change the firewall with `firewall-cmd`, not `nft`.

**From [Zones](./course-02-zones.md):**

- A zone bundles a target, services, ports, rich rules and the interfaces and sources bound to it.
- The built-in zones run from `drop` (silent) and `block` (reject) through `public` (the default) to `trusted` (everything allowed).
- A packet's zone is chosen by source binding first, then interface binding, then the default zone.

**From [Services, Ports And Rich Rules](./course-03-services-ports-richrules.md):**

- A service is a named bundle of ports; prefer `--add-service` over raw `--add-port` so the zone explains itself.
- firewalld always allows loopback, so test a zone with an address on one of its interfaces.
- A rich rule ties an allow or a deny to one source, with optional logging and rate limits, and is checked before plain allows.

**From [Runtime, Permanent And Operations](./course-04-runtime-permanent-operations.md):**

- Runtime changes go live at once and vanish on `--reload`; `--permanent` changes go to disk and need `--reload` to go live.
- `--runtime-to-permanent` saves the whole runtime set; `--set-default-zone` writes both copies at once.
- On a host managed by NetworkManager, set the zone on the connection (`connection.zone`).
- Removing `ssh`, a `drop` default zone, moving the management interface or `--panic-on` all lock you out.

## Your missions

You proved the skills in a graded mission right after the part that taught them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [firewalld Zones and Services Lab](./labs/lab-01/README.md) | Runtime, Permanent And Operations | open a service and a port in `public`, both live and saved |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You ran <code>firewall-cmd --permanent --add-service=http</code>, but <code>--list-services</code> does not show <code>http</code>. Why?</summary>

`--list-services` reads the runtime configuration, and `--permanent` only changed the saved one. Run `firewall-cmd --reload` to apply it.
</details>

<details>
<summary>2. You opened a port without <code>--permanent</code>, tested it, then ran <code>--reload</code>. Where is the port?</summary>

Gone. A reload throws the runtime configuration away. Run `--runtime-to-permanent` before the reload to keep it.
</details>

<details>
<summary>3. An interface was never assigned to a zone. Which zone handles its traffic?</summary>

The default zone, shown by `firewall-cmd --get-default-zone`.
</details>

<details>
<summary>4. A source address is bound to <code>drop</code>, and its interface is in <code>internal</code>. Which zone wins?</summary>

`drop`. A source binding beats an interface binding.
</details>

<details>
<summary>5. Which zone change option writes both the runtime and the permanent configuration at once?</summary>

`--set-default-zone`. Most other options change only one copy.
</details>

<details>
<summary>6. Why should you not add your own <code>nft</code> rules on a firewalld host?</summary>

firewalld rewrites `table inet firewalld` on every reload and does not know about your rules, so they can be checked in an order you did not intend. Use `firewall-cmd`, often with a rich rule.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy firewalld-zones-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-032
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.

> *firewalld is shield presets on top of nftables: pick the zone, allow the service, and make every change both live and saved.*
