---
estimated_duration: 25m
---

# Local Hostname Name Resolution Lab

A guided mission on one Ubuntu 24.04 training ship. You add a second IPv4 address and an IPv6 address next to the management address, make both survive a reboot, and make the name `app-srv1` resolve both ways through `/etc/hosts`. The step-by-step walkthrough is in [`solution.md`](./solution.md).

Start the mission from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-04/labs/lab-01
```

Open a terminal on the lab machine:

```sh
astrona ssh ats-003-lab-014
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

When the mission is done, remove it:

```sh
astrona destroy ats-003-lab-014
```
