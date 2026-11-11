# Question

Solve this question on: `terminal`

## Scenario

This is the capstone of this section. It pulls together interface addressing, persistent network configuration and local name resolution into one task, with no step-by-step guidance.

Astronaut, the data team wants the host `app-srv1` reachable on its own second address before they point their pipeline configuration at it.

The machine's primary interface already carries its management address, handed out by DHCP (the harbour master that gives arriving ships their call signs). That address and its default route carry your current session, so **do not remove or replace them.** Your job is to add new addresses next to the management address, and make them survive a reboot.

## Tasks

Work on the **primary network interface**: the one that holds the default route. This command names it:

```sh
ip -o -4 route show to default
```

1. **Secondary IPv4.** Add a second static IPv4 address `192.168.10.71/24` to that interface, *in addition to* the existing management address. The interface must end up with at least two IPv4 addresses.

2. **Static IPv6.** Add the static IPv6 address `fd00:10::70/64` to the same interface. It comes from the site's unique local address (ULA) range, the private range of IPv6. It must reach **global scope** with duplicate address detection finished: not left `tentative` and not `dadfailed`. It must also answer a local `ping -6 fd00:10::70`.

3. **Persistence.** Declare both the secondary IPv4 and the IPv6 address in on-disk network configuration, so a reboot brings them back. Use a file under `/etc/netplan/` or a NetworkManager connection profile. An address added only with `ip addr add` does **not** count.

4. **Name resolution.** In `/etc/hosts`, map the name `app-srv1` to `192.168.10.71` so that both directions resolve:
   - `getent hosts app-srv1` returns `192.168.10.71` (forward), and
   - `getent hosts 192.168.10.71` returns `app-srv1` (reverse).
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-01](../../../module-01/course.md), [module-02](../../../module-02/course.md), [module-03](../../../module-03/course.md), [module-04](../../../module-04/course.md), [module-05](../../../module-05/course.md).

The grader checks:

- Confirms the secondary IPv4 address 192.168.10.71/24 is live on the primary interface alongside the original address.
- Confirms the static IPv6 ULA fd00:10::70/64 is bound to the primary interface with global scope.
- Confirms fd00:10::70 actually answers a ping, not just appears in `ip addr`.
- Confirms getent hosts app-srv1 resolves to 192.168.10.71.
- Confirms getent hosts 192.168.10.71 resolves back to app-srv1.
- Confirms the secondary IPv4/IPv6 addresses are declared in a persistent Netplan or NetworkManager config, not only applied live.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
