---
estimated_duration: 15m
---

# Static Hostname Management Lab

A guided mission on one Ubuntu 24.04 training ship. You rename a freshly built machine to `web-srv1`, give it a pretty hostname, and fix its `127.0.1.1` line in `/etc/hosts`. The step-by-step walkthrough is in [`solution.md`](./solution.md).

Start the mission from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-010/module-02/labs/lab-01
```

Open a terminal on the lab machine:

```sh
astrona ssh ats-003-lab-012
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading from your own terminal:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the mission is done, remove it:

```sh
astrona destroy ats-003-lab-012
```
