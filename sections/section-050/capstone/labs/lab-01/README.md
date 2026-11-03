# Application Proxy and SSH Capstone Lab

The capstone mission for this section, with no step-by-step guidance. NGINX must proxy every path on one port to a fixed page of an existing app, and balance requests over two existing apps on another port, while the apps stay untouched.

## Run the mission

Start the training ship from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/capstone/labs/lab-01
```

Open a shell on it:

```sh
astrona ssh ats-003-lab-050
```

Read the task in [`question.md`](./question.md) and solve it on the training ship. Then send it for grading from your own terminal, not from inside the ship:

```sh
astrona submit -c sections/section-050/capstone/labs/lab-01
```

When you are done, remove the training ship. The command takes the lab's name, not its folder path:

```sh
astrona destroy ats-003-lab-050
```
