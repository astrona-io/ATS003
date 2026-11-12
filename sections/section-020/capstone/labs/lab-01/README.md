# Aggregation and Routing Capstone Lab

**Legacy exercise.** Repeats the static routing exercise. The main learning path uses [lab 023](../../../module-03/labs/lab-01/README.md). This ID remains runnable and covered by CI.

The section capstone: one static routing task on two training ships, `target` and `gateway`, with no step-by-step help. Add the route, prove it, and make it survive a reboot.

## Start the mission

Run this in your own terminal to start the lab:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-020/capstone/labs/lab-01
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading:

```bash
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the mission is done, remove it:

```bash
astrona destroy ats-003-lab-020
```
