# Private And Public Address Audit Lab

A graded mission on one Ubuntu 24.04 virtual machine. You find the private address the host's own interface carries and the public address the internet sees after NAT (network address translation), and write each one to a file under `/opt/course`.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-02/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-062`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-060/module-02/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-062
```
