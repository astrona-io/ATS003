# Make Routes Last

Astronaut, every lane you drew with `ip route` is chalked on the console: the next restart wipes it. In this part you prove that with a reboot, and learn where routes must be written so they come back. Then you take on the graded mission.

## Runtime against persistent routes

Routes created with `ip route` are runtime only, and a restart normally removes them. Persistent routes live in the distribution's network-management system, the flight manual for the communications array.

### Who keeps the routes

That system is one of NetworkManager, Netplan, `systemd-networkd`, `ifupdown` and others. On Ubuntu 24.04, Netplan keeps its YAML files under `/etc/netplan/`, and each interface can carry a list of `routes:` there.

Do not configure the same routes through more than one of these systems. They can then appear, disappear or change when you do not expect it.

### See it in your playground

<!-- astrona:playground:renew -->

This restarts the training ship and drops your SSH session for about a minute. Reconnect with `astrona ssh static-routing-playground`.

```sh
sudo reboot
```

After you reconnect, read the table again:

```sh
ip route show
```

The static routes and the extra default you added with `ip route` are gone. Only the connected routes and the management default remain. If the two lab interface addresses were set at runtime, add them again with `ip addr add` before you repeat any hands-on step.

## Common pitfalls

> [!WARNING]
> - **Trusting `ip route add` to survive a reboot.** It is runtime state only. Write the route into Netplan, `systemd-networkd` or NetworkManager if it must come back.
> - **Declaring a route in two systems.** Pick one network-management system for each interface.
> - **Editing the cloud-init Netplan file of the management interface.** Add your own file under `/etc/netplan/` instead, so you never break the link that carries your SSH session.

## Your mission: Multi-Interface Static Routing Lab

You can now add a static route, prove which way Linux sends a packet, test the next hop, and explain why a route needs persistent configuration. Now prove it in a graded mission: on a ship called `target`, add a route to a partner subnet through a relay ship called `gateway`, show it works end to end, and make it survive a reboot.

The mission runs on its own training ships, so first pause your playground. Nothing in it is lost:

```sh
astrona stop static-routing-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-03/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-023
astrona start static-routing-playground
```
