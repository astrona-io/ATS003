# Nginx Reverse Proxy Lab

A graded mission for the Nginx Reverse Proxy module. NGINX, the docking control tower of your training ship, must open two new ports: one that proxies every path to a fixed page of an existing app, and one that balances requests over two existing apps. The apps themselves stay untouched.

## Run the mission

Start the training ship from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-01/labs/lab-01
```

Open a shell on it:

```sh
astrona ssh ats-003-lab-051
```

Read the task in [`question.md`](./question.md) and solve it on the training ship. Then send it for grading from your own terminal, not from inside the ship:

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```

When you are done, remove the training ship. The command takes the lab's name, not its folder path:

```sh
astrona destroy ats-003-lab-051
```
