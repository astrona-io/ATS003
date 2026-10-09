# Section 050: Application Reverse Proxies (Nginx & SSH)

Astronaut, an app should never face the open galaxy on its own. In this section you build the docking control tower that stands in front of your apps, NGINX, and you tighten the airlock that every administrator uses to come aboard, the OpenSSH server.

## What you will be able to do

When you finish this section, you can:

- **Put NGINX in front of an app.** Forward a path to a backend with `proxy_pass`, control the path the backend sees with the trailing slash, pass the client's details on with `proxy_set_header`, and predict which `location` block wins.
- **Spread requests over several backends.** Build an `upstream` pool, choose round-robin, weights, `least_conn` or hashing, and let NGINX skip and retry a failing backend.
- **Harden the SSH server.** Read the effective configuration with `sshd -T`, turn off password and root login, limit who may log in, and write a `Match` block for one exception.

## The modules

Work through the modules in order. Each one has its own playground and a graded mission.

1. [Nginx Reverse Proxy](./module-01/course.md): turn NGINX into a reverse proxy and read its errors.
2. [Nginx Load Balancers](./module-02/course.md): share requests over a pool, and survive a failing backend.
3. [OpenSSH Server Hardening](./module-03/course.md): rewrite the airlock guard's standing orders, safely.

## Check yourself and the capstone

- [Section 050 knowledge check](./quiz.md): short scenario questions on everything in this section.
- [Section capstone: Application Proxy and SSH Capstone Lab](./capstone/labs/lab-01/README.md): one integrated reverse proxy and load balancer task with no step-by-step guidance. Start it with:

  ```sh
  astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/capstone/labs/lab-01
  ```
