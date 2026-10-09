# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about keeping one ship's clock in step with a time beacon, using chrony as the NTP client.

**From [Why Clocks Drift](./course-01-why-clocks-drift.md):**

- A computer clock drifts by seconds per day. Wrong time breaks certificate checks, Kerberos logins (more than five minutes of difference), log correlation and scheduled jobs.
- NTP keeps the clock right. On Ubuntu, `chronyd` is the service that corrects the clock, and `chronyc` is the tool you talk to it with.
- Stratum counts the relays from a reference clock. A client ends up one stratum below the source it locks onto.
- Only one time service may steer the clock at a time.
- With no sources, `chronyc tracking` shows `Reference ID : 00000000`, `Stratum : 0` and `Leap status : Not synchronised`.

**From [Add A Time Source](./course-02-add-a-time-source.md):**

- `server` names one time source; `pool` names a DNS name for several servers.
- `iburst` makes the first sync take seconds instead of minutes. `minpoll` and `maxpoll` are powers of two seconds (`4` = 16 seconds, `10` = 1024 seconds).
- `sudo chronyc add server <address> iburst` adds a source to the running service only.
- In `chronyc sources`, `^*` marks the selected server. `Reach` is octal and climbs to `377` when the last eight polls were answered.
- In `chronyc tracking`, `Leap status : Normal` means synchronised.

**From [Write The Source Into The Configuration File](./course-03-write-the-source-into-the-configuration-file.md):**

- A restart throws away every source added with `chronyc add`.
- A `server` line in `/etc/chrony/chrony.conf` survives restarts and reboots.
- chrony reads the file only when it starts, so every edit needs `sudo systemctl restart chrony`.

**From [Slew, Step And The System View](./course-04-slew-step-and-the-system-view.md):**

- Slewing corrects the clock gradually and never jumps; stepping jumps in one move.
- `makestep 1 3` (Ubuntu's default) allows automatic steps only during the first three updates after start. `sudo chronyc makestep` steps by hand.
- `timedatectl` shows `System clock synchronized: yes` and `NTP service: active` once a time service has locked on.

## Your missions

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [NTP Client Time Synchronization Lab](./labs/lab-01/README.md) | Write The Source Into The Configuration File | replace chrony's sources with four tuned `server` lines and get the clock synchronised |

If you skipped it, go back to it now. The mission is short, and the exam asks for exactly this skill.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You ran <code>sudo chronyc add server 192.168.100.10 iburst</code> and the client synced. After a reboot it has no sources. Why?</summary>

`chronyc add` changes only the running service. Nothing was written to `/etc/chrony/chrony.conf`, so after the restart chrony knows only the sources in the file. Add a `server` line to the file and restart chrony.
</details>

<details>
<summary>2. What does <code>maxpoll 10</code> mean?</summary>

chrony polls that source no less often than every 2 to the power of 10 seconds, that is, 1024 seconds. The poll values are powers of two, not seconds.
</details>

<details>
<summary>3. A source shows <code>Reach 17</code> a few seconds after you added it. Is something broken?</summary>

No. `Reach` is octal and fills up over the first eight polls. A low value soon after adding a source is normal; it climbs to `377` when the last eight polls were all answered.
</details>

<details>
<summary>4. What does <code>^*</code> at the start of a line in <code>chronyc sources</code> mean?</summary>

`^` means the source is a server, and `*` means it is the source chrony is synchronised to right now.
</details>

<details>
<summary>5. You edited <code>chrony.conf</code>, but <code>chronyc sources</code> still shows the old list. What did you forget?</summary>

The restart. chrony reads the configuration file only when it starts: run `sudo systemctl restart chrony`.
</details>

<details>
<summary>6. Long after boot, the clock is suddenly 30 seconds off. Will chrony step it back?</summary>

Not by itself. `makestep` only allows automatic steps during the first few updates after chrony starts. Later, chrony slews the error out slowly, unless you run `sudo chronyc makestep`.
</details>

## Clean up the playground

Your playground is two training ships running on your machine. When you are done with this module, remove them, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ntp-chrony-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-041
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
