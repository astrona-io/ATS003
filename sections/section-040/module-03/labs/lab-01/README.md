---
estimated_duration: 20m
---

# DNS Verification with dig Lab

Astronaut, this is a graded mission. Point a client's resolver at an internal Domain Name System (DNS) server and prove its records with `dig`. The task is in [`question.md`](./question.md), and a step-by-step walkthrough is in [`solution.md`](./solution.md).

Start the mission from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/module-03/labs/lab-01
```

Open a shell on the lab machine with `astrona ssh`, and solve the task there. When you think you are done, send it for grading from your own terminal (not inside the lab machine):

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When you are finished, remove the mission. The command takes its name, not its folder path:

```sh
astrona destroy ats-003-lab-043
```
