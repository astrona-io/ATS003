# DNS Client Resolution Lab

A graded mission on one Ubuntu 24.04 virtual machine. A DNS server for `lab.example` runs on `10.55.0.53`, but the resolver on this ship does not know it. You teach the resolver with a drop-in file, make the short name `db` work through a search domain and override one name in `/etc/hosts`.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-040/module-04/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-044`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-040/module-04/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-044
```
