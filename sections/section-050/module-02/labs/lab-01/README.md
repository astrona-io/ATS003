# Nginx Upstream Load Balancers Lab

A graded mission for the Nginx Load Balancers module. You build an `upstream` pool over two existing apps on one port, and a proxy to a fixed page of one app on another port, without changing the apps.

## Run the mission

Start the training ship from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-02/labs/lab-01
```

Open a shell on it:

```sh
astrona ssh ats-003-lab-052
```

Read the task in [`question.md`](./question.md) and solve it on the training ship. Then send it for grading from your own terminal, not from inside the ship:

```sh
astrona submit -c sections/section-050/module-02/labs/lab-01
```

When you are done, remove the training ship. The command takes the lab's name, not its folder path:

```sh
astrona destroy ats-003-lab-052
```
