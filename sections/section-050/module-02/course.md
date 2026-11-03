# Nginx Load Balancers

Astronaut, a docking control tower in front of **one** bay only routes visitors. A tower in front of **several identical bays** also shares the visitors out and keeps working when one bay fails. That is **load balancing**. In NGINX it is the same `proxy_pass` you already know, pointed at a named group of backends instead of a single address.

This module is about the two decisions that shape how the tower shares visitors: **which method** picks the backend, and **what happens when one is unhealthy**.

## Learning objectives

After this module you can:

- Define an `upstream` pool and point a proxied `location` at it.
- Choose a balancing method (weighted round-robin, `least_conn`, `hash` or `ip_hash`) and explain when each one fits.
- Set `weight`, `backup` and `down` on a pool member and predict the traffic split.
- Explain the passive health checks of NGINX (`max_fails`, `fail_timeout`) and how they differ from active probing.
- Use `proxy_next_upstream` to retry a failed request on another backend, and say why `POST` requests are left out by default.
- Trace uneven or stuck traffic back to the balancing method and the client's address.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **The shell.** You can open a shell, use `sudo` and edit a text file.
- **NGINX as a reverse proxy.** `proxy_pass` inside a `location` block forwards requests to a backend, and `proxy_set_header Host $host;` passes the client's host name on. You apply every change with `sudo nginx -t && sudo systemctl reload nginx`.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine named `nginx-lb-playground`. Open a shell on it with `astrona ssh nginx-lb-playground`. Inside you find:

- **NGINX**, serving its stock default page on port 80, and a **working round-robin load balancer on port 8080**, defined in `/etc/nginx/conf.d/lb.conf`.
- An `upstream app_pool` over **three echo backends**: `backend-1`, `backend-2` and `backend-3` on `127.0.0.1:9001`, `:9002` and `:9003`. Each reply names the backend that produced it. They accept `?ms=N` to answer after a delay of N milliseconds.
- `curl` and `python3`, and `sudo` with no password.

You change the load balancer by editing `/etc/nginx/conf.d/lb.conf`. `curl` runs on this machine, so every request comes from the same client address, which matters for `ip_hash`. There is no TLS (Transport Layer Security). This is the free, open source NGINX, so the `health_check` and `slow_start` directives of the paid NGINX Plus are not available.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [The Pool And Round-Robin](./course-01-the-pool-and-round-robin.md): the `upstream` block, the default rotation, and weights.
2. [Least Connections And Hashing](./course-02-least-connections-and-hashing.md): follow the load, or keep related requests on one backend.
3. [Health Checks And Retries](./course-03-health-checks-and-retries.md): drop a failing backend, and retry a request somewhere else.
4. [Wrap-Up: Mission Debrief](./course-04-wrap-up.md): what you learned, your mission, and cleaning up.

## Why this matters

One backend is one point of failure. A pool behind a load balancer survives a crashed backend and spreads the work, and the exam expects you to build one from memory.

The hard part is not the syntax. It is predicting where each request goes, and knowing that the free NGINX only notices a dead backend when real requests fail. This module makes both visible.
