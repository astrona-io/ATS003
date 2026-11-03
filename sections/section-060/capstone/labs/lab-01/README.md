# Connection Recovery and Audit Capstone Lab

The section 060 capstone: one graded task with no step-by-step guidance. It runs on one Ubuntu 24.04 virtual machine. The web application `myapp` listens on port 8080, but an nftables rule silently drops its traffic. You confirm the listener with `ss`, remove the rule, and prove the application answers with `curl`.

## Start the lab

Start the lab from your own terminal:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-060/capstone/labs/lab-01
```

Open a terminal on the lab machine with `astrona ssh ats-003-lab-060`, then read the task in [`question.md`](./question.md).

## Grade and clean up

Grading runs from your own terminal, not inside the lab machine:

```bash
astrona submit -c sections/section-060/capstone/labs/lab-01
```

When you are done, remove the lab. The command takes the lab's name, not its folder path:

```bash
astrona destroy ats-003-lab-060
```
