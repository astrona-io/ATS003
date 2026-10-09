# Write The Source Into The Configuration File

Astronaut, a source you add with `chronyc add` is chalked on the console: it is gone the moment the clockmaster restarts. In this part you prove that, then write the source into chrony's flight manual, its configuration file, so it survives every restart and reboot.

## Runtime changes do not survive a restart

`chronyc add` changes only the running `chronyd` service. Nothing is written to disk. When `chronyd` starts again, it reads `/etc/chrony/chrony.conf` and knows only the sources listed there.

### See the runtime source disappear

<!-- astrona:playground:renew -->

On `ntp-client`, with a source added earlier through `sudo chronyc add server 192.168.100.10 iburst`, restart chrony and list the sources:

```sh
sudo systemctl restart chrony
chronyc sources
```

Expect `Number of sources = 0` again. The restart threw away the source you added at runtime, because the configuration file never mentioned it.

## Make the source persistent

To keep a source across restarts and reboots, it has to be a line in the configuration file. `chronyd` reads that file once, when it starts.

### Add the line and restart

Add this line to the end of `/etc/chrony/chrony.conf` (for example with `sudo nano /etc/chrony/chrony.conf`):

```text
server 192.168.100.10 iburst
```

Apply it:

```sh
sudo systemctl restart chrony
```

Then check the result:

```sh
chronyc sources -v
```

This time the source is back after the restart, and after a few seconds it carries the `*` that marks the selected source again.

### The file is read only at start

Editing the configuration file without restarting has no effect, and neither does `sudo systemctl reload chrony`. chrony reads the file only when it starts. So the habit is always the same three steps: edit the file, restart chrony, check with `chronyc`.

> [!TIP]
> On the exam, finish every chrony change with `chronyc sources -v` and `chronyc tracking`. A `*` in the sources table and `Leap status : Normal` in tracking prove that the clockmaster really uses your new file.

## Common pitfalls

> [!WARNING]
> - **`chronyc add` treated as permanent.** A source added at runtime is gone on the next restart. Put it in `chrony.conf` to keep it.
> - **Editing `chrony.conf` without restarting.** chrony reads the file only at start: no restart, no change.
> - **Editing the wrong file.** On Ubuntu the file is `/etc/chrony/chrony.conf`. `/etc/chrony.conf` is the Red Hat family location.
> - **Leaving the old sources in place.** The default file already has `pool` lines. If a task asks for an exact list of sources, comment out (`#`) or delete every line that is not on the list.

## Your mission: NTP Client Time Synchronization Lab

You can now add a time source, read whether chrony locked on, and write the source into the configuration file so it survives a restart. Now prove it in a graded mission: replace chrony's default sources with four named servers, each with tuned poll limits, and get the clock synchronised.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ntp-chrony-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-01/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-041
astrona start ntp-chrony-playground
```
