# Packet Filtering with nftables Lab

A graded mission on one training ship (an Ubuntu 24.04 virtual machine) with an empty nftables ruleset. You build a filter table and a NAT table by hand: a dropped port, a port redirect, a port limited to one source, and a block on outgoing traffic to one host.

## Start the mission

Run this in your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-030/module-01/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-031`, and read the task in [question.md](./question.md).

## Grade and clean up

When you think you are done, send it for grading from your own terminal:

```bash
astrona submit -c sections/section-030/module-01/labs/lab-01
```

Then remove the lab. The command takes its name, not its folder path:

```bash
astrona destroy ats-003-lab-031
```
