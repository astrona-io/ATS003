# Question

Solve this question on: `terminal`

## Scenario

Astronaut, this training ship runs `firewalld`, a service that manages the
shields through zones (shield presets for a group of network interfaces).
`firewalld` is installed, running and enabled at boot. The primary network
interface, the one that holds the default route, is already bound to the
`public` zone, and `public` is also the default zone.

Your job is to open two things in that zone, and to make each change both
**live now** and **saved for after a reload or a reboot**.

## Tasks

In the `public` zone:

1. **Allow the `https` service.** It must appear in both the runtime service
   list and the permanent service list.

2. **Allow port `8443/tcp`.** It must appear in both the runtime port list
   and the permanent port list.

## Keep these as they are

The checker also confirms the starting state is still in place:

- `firewalld` stays running and enabled.
- The default zone stays `public`.
- The primary interface stays bound to the `public` zone.
