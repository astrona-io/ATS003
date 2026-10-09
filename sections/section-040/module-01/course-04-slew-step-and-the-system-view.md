# Slew, Step And The System View

Astronaut, once the clockmaster has a time beacon, it still has to bring the ship's clock into line. It can do that gently or in one jump. This part shows both ways, and then the one command that reports the ship's time status no matter which time service runs.

## Slewing versus stepping the clock

chrony corrects the clock in two ways. Which one it uses matters, because some software handles a jump in time badly.

### Two ways to correct

- **Slewing** speeds the clock up or slows it down slightly until it catches up. The clock never jumps and never goes backwards. chrony uses it for small offsets.
- **Stepping** sets the clock to the correct time in one jump. It is fast, but time can appear to move backwards, which some software handles badly. chrony uses it only when the offset is too large to slew in a reasonable time.

### The `makestep` directive

The `makestep <threshold> <limit>` directive in the configuration file controls automatic stepping. If the offset is larger than `<threshold>` seconds, chrony may step, but only for the first `<limit>` clock updates after it starts. So a machine can jump to the right time at boot, and after that it only ever slews.

Ubuntu's default is `makestep 1 3`. The command `chronyc makestep` forces a step by hand at any time.

## Knock the clock off and watch chrony pull it back

The best way to see slewing is to cause a small error on purpose. Your playground client must already be synchronised to `192.168.100.10` for this to work.

### Add a two-second error

<!-- astrona:playground:renew -->

On `ntp-client`, move the clock forward two seconds and look at the offset:

```sh
sudo date -s '+2 seconds'
chronyc tracking | grep -E 'System time|Last offset'
```

Expect `System time` to jump to about 2 seconds off, then shrink over the next minute or two as chrony slews:

```text
System time     : 1.998xxx seconds fast of NTP time
Last offset     : +1.998xxx seconds
```

Run the `chronyc tracking` line again every 20 seconds. The offset falls steadily instead of snapping to zero: that is slewing.

### Finish the correction in one jump

To finish the correction at once instead, force a step:

```sh
sudo chronyc makestep
chronyc tracking | grep 'System time'
```

`makestep` jumps the clock the rest of the way in one move. That is the stepping behaviour, on demand.

## The system view: `timedatectl`

chrony is one time service among several (`systemd-timesyncd`, `ntpd`, `ntpsec`). `timedatectl` is part of systemd. It reports the system's synchronisation state without caring which service does the work.

### Confirm the system considers itself synced

Ask systemd for the time status:

```sh
timedatectl
```

Expect:

```text
               Local time: Fri 2026-08-29 12:05:00 UTC
           Universal time: Fri 2026-08-29 12:05:00 UTC
                 RTC time: Fri 2026-08-29 12:05:00
                Time zone: UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
```

`NTP service: active` means a time service (chrony, here) is running, and `timedatectl` lets it manage the clock. `System clock synchronized: yes` appears once that service reports a lock. Before the client had a source, this line read `no`.

## Common pitfalls

> [!WARNING]
> - **Assuming a large offset gets stepped.** `makestep` only steps automatically for the first few updates after chrony starts (its `<limit>`). A big jump introduced later is slewed slowly unless you run `chronyc makestep`.
> - **Testing slewing on a client with no source.** With no source selected, chrony has nothing to correct towards, and the offset never shrinks.
> - **Two time services at once.** `systemd-timesyncd` and chrony both running will conflict. `timedatectl` shows which service is active; disable the one you are not using (`sudo systemctl disable --now systemd-timesyncd`).
