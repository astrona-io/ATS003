# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about NetworkManager: the communications officer that keeps network settings in the flight manual and applies them at every boot.

**From [Devices And Connection Profiles](./course-01-devices-and-profiles.md):**

- Settings made with `ip addr add` or `ip route add` live only in the running kernel and vanish on reboot.
- NetworkManager, systemd-networkd, Netplan and ifupdown all keep settings on disk. Exactly one should own each interface.
- A **device** is an interface the kernel has; a **connection profile** is a saved, named bundle of settings. One device can have several profiles, with one active at a time.
- `nmcli device status` shows each device's state: `connected`, `disconnected`, `unavailable` or `unmanaged`.

**From [Create A Static Profile](./course-02-create-a-static-profile.md):**

- `nmcli connection add` with `ipv4.method manual` and `ipv4.addresses` creates a static profile. `con-name` is the profile's name, `ifname` the interface.
- Creating a profile does not apply it; `nmcli connection up` does.
- Profiles are saved as keyfiles in `/etc/NetworkManager/system-connections/<con-name>.nmconnection`, root-only with mode `600`.
- After a hand edit of a keyfile, run `sudo nmcli connection reload`.

**From [Change, Reactivate And Keep A Profile](./course-03-change-and-reactivate.md):**

- `nmcli connection modify` changes only the saved profile. The interface changes on the next `nmcli connection up` or `nmcli device reapply`.
- `+` adds to a list, `-` removes from it, and a plain setting replaces the whole list.
- `ipv4.method auto` needs a DHCP (Dynamic Host Configuration Protocol) server. With none, activation fails with `IP configuration could not be reserved`.
- `connection.autoconnect yes` brings a profile back at boot and often right after a `down`; `nmcli device disconnect` is the stronger stop.
- An `unmanaged` device is owned by another tool or excluded by a rule such as `unmanaged-devices=` in `/etc/NetworkManager/conf.d/`.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Private And Public Address Audit Lab](./labs/lab-01/README.md) | Change, Reactivate And Keep A Profile | find the private address on the host's interface and the public address seen after NAT |

If you skipped it, go back to it now. It is short, and the exam expects you to read addresses quickly.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You add an address with <code>ip addr add</code> and reboot. Is it still there?</summary>

No. `ip` changes live only in the running kernel. To keep an address, put it in a profile that a network manager applies at boot.
</details>

<details>
<summary>2. You ran <code>nmcli connection modify lab-static +ipv4.addresses 192.168.120.51/24</code>, but <code>ip addr</code> does not show the new address. Why?</summary>

`modify` only changes the saved profile. Run `sudo nmcli connection up lab-static` (or `nmcli device reapply`) to apply it to the interface.
</details>

<details>
<summary>3. Where does NetworkManager save a profile called <code>lab-static</code>?</summary>

In `/etc/NetworkManager/system-connections/lab-static.nmconnection`, an INI-style keyfile that only root can read.
</details>

<details>
<summary>4. You ran <code>nmcli connection down lab-static</code>, and two seconds later it is active again. What happened?</summary>

`connection.autoconnect` is `yes`, so NetworkManager brought it straight back. Set autoconnect to `no`, or use `nmcli device disconnect` on the device.
</details>

<details>
<summary>5. <code>nmcli device status</code> shows an interface as <code>unmanaged</code>. What does that tell you?</summary>

NetworkManager will not configure it. Another tool such as Netplan, systemd-networkd or ifupdown owns it, or a rule like `unmanaged-devices=` excludes it.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy networkmanager-nmcli-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-061
```

Then run `astrona list` once more and check that neither name appears any longer.

You can start the playground again at any time with the `astrona run` command for this module's playground. It always starts clean, so nothing you changed carries over.
