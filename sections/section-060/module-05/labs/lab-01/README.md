# Network troubleshooting capstone

A graded mission on one Ubuntu 24.04 virtual machine. The web service `portal` is running, but clients cannot reach it at `http://portal.lab:8443/`. Several rungs of the troubleshooting ladder are broken. You find each one in order, fix it and prove the portal answers.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-060/module-05/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-065`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-060/module-05/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-065
```
