---
estimated_duration: 15m
---

# Public IP Discovery Behind NAT Lab

A guided mission on one Ubuntu 24.04 training ship. You find the machine's private address and the public address the internet sees after NAT (network address translation), and write each one to the file an audit script reads. The step-by-step walkthrough is in [`solution.md`](./solution.md).

Start the mission from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-03/labs/lab-01
```

Open a terminal on the lab machine:

```sh
astrona ssh ats-003-lab-013
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the mission is done, remove it:

```sh
astrona destroy ats-003-lab-013
```
