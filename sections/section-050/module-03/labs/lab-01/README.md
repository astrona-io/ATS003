# OpenSSH Server Hardening Lab

A graded mission for the OpenSSH Server Hardening module. You tighten the standing orders of the airlock guard, `sshd`: no X11 forwarding, password login for one user only, and a login banner for both users.

## Run the mission

Start the training ship from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-03/labs/lab-01
```

Open a shell on it:

```sh
astrona ssh ats-003-lab-053
```

Read the task in [`question.md`](./question.md) and solve it on the training ship. Then send it for grading from your own terminal, not from inside the ship:

```sh
astrona submit -c sections/section-050/module-03/labs/lab-01
```

When you are done, remove the training ship. The command takes the lab's name, not its folder path:

```sh
astrona destroy ats-003-lab-053
```
