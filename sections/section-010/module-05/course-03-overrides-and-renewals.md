# Overrides And Renewals

Astronaut, a harbour master is helpful, but it does not know your mission. Sometimes you want the call sign and nothing else: no new default lane, no new directory. Netplan's `dhcp4-overrides` lets you accept only the parts of a lease you want.

## Refuse parts of the lease

The `dhcp4-overrides` block sits next to `dhcp4: true`. These keys are the ones to remember:

| Key | Effect |
| --- | --- |
| `use-routes: false` | ignore the router and the routes from the lease |
| `use-dns: false` | ignore the DNS servers from the lease |
| `use-hostname: false` | do not take a host name from the lease |
| `route-metric: 250` | give the routes from the lease a cost, so a lower-cost lane wins |

### Write the file

<!-- astrona:playground:renew -->

Replace the file with this version. Save this as `/etc/netplan/70-dhcp0.yaml`:

```yaml
network:
  version: 2
  ethernets:
    dhcp0:
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
        use-dns: false
```

Apply it:

```sh
sudo netplan apply
```

Then check the result:

```sh
ip -br addr show dhcp0
ip route show default
resolvectl dns dhcp0
```

The address from the lease is still there. The default route through `10.77.0.1` is gone, and the directory list for `dhcp0` is empty. The interface kept only the call sign.

## Renew the lease by hand

A renewal asks the same server to extend the loan. A reconfigure throws the old state away and starts again.

### See it work

```sh
sudo networkctl renew dhcp0
sudo networkctl reconfigure dhcp0
```

After the renewal, `networkctl status dhcp0` shows the lease time counting from the new start. If you have `tcpdump` running in a second shell, you see a new Request and Acknowledge.

## Static or dynamic?

Use DHCP for ordinary clients. Use a static address for anything that others must find by address, such as a server or a router. Some networks use a DHCP reservation, where the server always gives the same address to one MAC address. That is a server setting and not part of the client.

## Common pitfalls

> [!WARNING]
> - **Forgetting to re-apply.** The override only takes effect after `sudo netplan apply`.
> - **`use-routes: false` and no other route.** Without a default route the ship cannot reach the rest of the galaxy. Make sure another lane exists.
> - **Mixing static and dynamic.** A static address and `dhcp4: true` on one interface give the ship two call signs. Choose one.
> - **Expecting a hostname change.** A host name from the lease is only used if the static host name is not set.

## Your mission: DHCP Client Lab

You can now turn DHCP on, read a lease and refuse parts of it. The graded mission gives you a fresh ship with a harbour master and a bare client antenna: you configure the client and keep it from taking the default route and the directory servers.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop dhcp-client-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-05/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-05/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-015
astrona start dhcp-client-playground
```
