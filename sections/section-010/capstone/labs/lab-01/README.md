---
estimated_duration: 30m
---

# Core Host Configurations Capstone Lab

The capstone of this section, on one Ubuntu 24.04 training ship, with no step-by-step guidance. You add new IPv4 and IPv6 addresses next to the management address, make them persistent, and make the name `app-srv1` resolve both ways. Try it on your own first; the walkthrough in [`solution.md`](./solution.md) is there if you get stuck.

Start the mission from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/capstone/labs/lab-01
```

Open a terminal on the lab machine:

```sh
astrona ssh ats-003-lab-010
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading from your own terminal:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the mission is done, remove it:

```sh
astrona destroy ats-003-lab-010
```
