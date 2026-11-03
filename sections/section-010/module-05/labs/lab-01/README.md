# DHCP Client Lab

A graded mission on one Ubuntu 24.04 virtual machine. A DHCP server answers on the antenna `dhcpsrv0`. Your client antenna `dhcp0` has no configuration. You turn on DHCP for it, but you keep the address only: no default route and no DNS servers from the lease.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-010/module-05/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-015`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-010/module-05/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-015
```
