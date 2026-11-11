# Summary

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
- Profiles may be stored as root-only keyfiles in `/etc/NetworkManager/system-connections/`. On this Ubuntu image, NetworkManager can persist them through Netplan YAML instead.
- After a hand edit of a keyfile, run `sudo nmcli connection reload`.

**From [Change, Reactivate And Keep A Profile](./course-03-change-and-reactivate.md):**

- `nmcli connection modify` changes only the saved profile. The interface changes on the next `nmcli connection up` or `nmcli device reapply`.
- `+` adds to a list, `-` removes from it, and a plain setting replaces the whole list.
- `ipv4.method auto` needs a DHCP (Dynamic Host Configuration Protocol) server. With none, activation fails with `IP configuration could not be reserved`.
- `connection.autoconnect yes` permits activation at boot. A manual `connection down` blocks automatic reactivation of that profile until it is explicitly activated or the relevant state resets.
- An `unmanaged` device is owned by another tool or excluded by a rule such as `unmanaged-devices=` in `/etc/NetworkManager/conf.d/`.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Repair a persistent NetworkManager profile](./labs/lab-01/README.md) | Focused practice | Diagnose the saved and active settings of lab-static; Correct its address and enable autoconnect; Reactivate the profile and verify it after reboot |

Complete the profile-repair lab before moving on; it checks both persistent configuration and live behavior.

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

With the keyfile backend, look in `/etc/NetworkManager/system-connections/`. On this Ubuntu image, inspect `/etc/netplan/` as well: NetworkManager can persist the profile through Netplan. Use `nmcli connection show lab-static` to inspect its settings regardless of the storage backend.
</details>

<details>
<summary>4. Does <code>nmcli connection down lab-static</code> followed by a short wait prove autoconnect works at boot?</summary>

No. A manual down blocks automatic reactivation of that profile. Inspect the saved autoconnect setting, activate the profile explicitly, reboot, and check the live address and active profile again.
</details>

<details>
<summary>5. <code>nmcli device status</code> shows an interface as <code>unmanaged</code>. What does that tell you?</summary>

NetworkManager will not configure it. Another tool such as Netplan, systemd-networkd or ifupdown owns it, or a rule like `unmanaged-devices=` excludes it.
</details>

<!-- astrona:playground:destroy -->
