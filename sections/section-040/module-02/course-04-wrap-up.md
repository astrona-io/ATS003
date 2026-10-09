# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about turning a chrony client into an NTP server that other ships set their clocks from.

**From [One Service, Two Jobs](./course-01-one-service-two-jobs.md):**

- The same `chronyd` service that syncs a clock can also serve time. There is no separate server program.
- By default, `chronyd` answers no one. On the client, the refused source shows as `^?` with `Reach 0`.
- Run three or four internal servers, so clients can outvote a falseticker and survive one server going down.
- Stratum counts hops from a reference clock: 0 is the reference clock, 16 means not synchronised, and a client is always one above its server.
- `Reference ID : 7F7F0100` with an empty name means the server refers to its own clock.

**From [Open The Server With `allow`](./course-02-open-the-server-with-allow.md):**

- An `allow <subnet>` line in `/etc/chrony/chrony.conf`, plus a restart, opens the server to that range. `deny` cuts exceptions out, and the more specific prefix wins.
- On the client, the source flips from `^?` to `^*` within a poll or two.
- `sudo chronyc serverstats` shows the packet counters, and `sudo chronyc clients` lists the machines that asked for the time.
- `chronyc allow` and `chronyc deny` change access only until the next restart.

**From [Local Stratum And Firewalls](./course-03-local-stratum-and-firewalls.md):**

- `local stratum <n>` lets a server with no upstream serve time at stratum `<n>`. Keep `<n>` at 10 or above, and use it only on isolated networks.
- NTP uses UDP port 123. `allow` is chrony's own check; the firewall needs its own rule for incoming UDP port 123.

## Your missions

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [NTP Server Mode and Stratums Lab](./labs/lab-01/README.md) | Open The Server With `allow` | turn one machine into an internal time server and sync a second machine through it |

If you skipped it, go back to it now. The mission is short, and the exam asks for exactly this skill.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. chrony runs on the server and has good time, but the client's source stays at <code>^?</code> with <code>Reach 0</code>. What is missing first?</summary>

An `allow` line for the client's address or subnet in the server's `/etc/chrony/chrony.conf`, followed by `sudo systemctl restart chrony`. By default, chrony answers no one.
</details>

<details>
<summary>2. A server syncs to a stratum 2 upstream. Which stratum do its clients show?</summary>

Stratum 4. The server serves stratum 3 (one above its upstream), and its clients are one above that.
</details>

<details>
<summary>3. You ran <code>sudo chronyc allow 192.168.101.0/24</code> and it worked. After a reboot, the clients are refused again. Why?</summary>

`chronyc allow` changes only the running service. To keep the rule, put `allow 192.168.101.0/24` in `chrony.conf`.
</details>

<details>
<summary>4. How do you prove from the server that a client really asked it for the time?</summary>

Run `sudo chronyc serverstats` (the `NTP packets received` counter goes up) and `sudo chronyc clients` (the client's address is listed).
</details>

<details>
<summary>5. The <code>allow</code> line is correct and chrony was restarted, but clients still time out. The server runs firewalld. What do you add?</summary>

A firewall rule for incoming UDP port 123, for example `sudo firewall-cmd --permanent --add-service=ntp && sudo firewall-cmd --reload`. `allow` is only chrony's own check.
</details>

<details>
<summary>6. Why should <code>local stratum</code> be 10 or higher?</summary>

So that real servers with a lower stratum win when they are reachable. A low number would make clients prefer this server's unchecked time.
</details>

## Clean up the playground

Your playground is two training ships running on your machine. When you are done with this module, remove them, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ntp-server-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-042
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
