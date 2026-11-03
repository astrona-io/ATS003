# Software Bridging Lab

A graded mission on one training ship. You build a bridge and an active-backup bond on three practice interfaces, and make both survive a reboot.

## Start the mission

Run this in your own terminal to start the lab:

```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c sections/section-020/module-02/labs/lab-01
```

Read the task in [`question.md`](./question.md). When you think you are done, send it for grading:

```bash
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the mission is done, remove it:

```bash
astrona destroy ats-003-lab-022
```
