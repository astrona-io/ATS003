# OpenSSH Client Lab

A graded mission on one Ubuntu 24.04 virtual machine. You work as the user `cadet`: create a key, install it on the station with `ssh-copy-id`, trust its host key, write a `Host station` entry in `~/.ssh/config` and keep a tunnel open to a web service that listens on loopback only.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-04/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-054`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-050/module-04/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-054
```
