# Nginx Reverse Proxy

Astronaut, your ship now carries a docking control tower. Visitors never fly straight into a cargo bay. They call the tower, and the tower forwards them to the right bay. That tower is a **reverse proxy**: a server that takes requests from clients, makes its own request to a backend server, and hands the answer back. The client only ever talks to the proxy. It never sees the backend, and often does not know one exists.

In this module the tower is **NGINX** (said "engine X"), the web server most Linux machines use for this job. You will turn it from a plain web server into a proxy, steer requests by their path, pass the visitor's details on to the backend, and spread visitors over several bays.

## Learning objectives

After this module you can:

- Explain what a reverse proxy does: it ends the client's connection, makes its own backend request, and returns the response. Say how it differs from a forward proxy.
- Find the NGINX configuration (`nginx.conf`, `sites-enabled/`, `conf.d/`) and place a `proxy_pass` inside a `server` and `location` block.
- Predict how a `proxy_pass` address, with or without a trailing slash, changes the path sent to the backend.
- Forward the client's `Host` and IP address with `proxy_set_header`, and explain why the backend needs them.
- Predict which `location` block NGINX picks when several could match.
- Define an `upstream` group and describe the default round-robin balancing.
- Find the cause of a `502` or `504` from a proxied location with the response and `error.log`.

## Before you start

Every mission starts with a pre-flight check. Make sure you have the basics this module expects, and know what is waiting in your playground.

### What you should already know

- **The shell.** You can open a shell, use `sudo` and edit a text file.
- **The web.** An HTTP (HyperText Transfer Protocol) request is a signal with a method (`GET`), a path (`/hello`) and headers (`Host: shop.example`). You send them with `curl`.

### What is in your playground

Your playground is one training ship: an Ubuntu 24.04 virtual machine named `nginx-proxy-playground`. Open a shell on it with `astrona ssh nginx-proxy-playground`. Inside you find:

- **NGINX**, serving its stock default page on port 80. There is no proxy configuration yet. Writing it is your job.
- **Two backend apps** that echo what they receive, as plain text: `backend-a` on `127.0.0.1:9001` and `backend-b` on `127.0.0.1:9002`. Each reply prints the method, the exact `path` it was asked for, and the `Host`, `X-Forwarded-For`, `X-Real-IP` and `X-Forwarded-Proto` headers it saw.
- `curl` and `python3`, and `sudo` with no password.

You edit `/etc/nginx/sites-available/default` (it is already enabled) or add a file under `/etc/nginx/conf.d/`. After every change, apply it with `sudo nginx -t && sudo systemctl reload nginx`. `curl` runs on the same machine, so the client address the backends see is always `127.0.0.1`. There is no TLS (Transport Layer Security) here: port 80 only.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->

## The parts of this module

1. [What A Reverse Proxy Does](./course-01-what-a-reverse-proxy-does.md): the tower's job, the `nginx` command, and where the configuration lives.
2. [A First Proxy And The Trailing Slash](./course-02-a-first-proxy-and-the-trailing-slash.md): forward one path to a backend, and control the path the backend sees.
3. [Headers And Location Matching](./course-03-headers-and-location-matching.md): pass the visitor's details on, and predict which `location` wins.
4. [Upstream Pools And Failing Backends](./course-04-upstream-pools-and-failing-backends.md): spread requests over several backends, and read a `502`.
5. [Wrap-Up: Mission Debrief](./course-05-wrap-up.md): what you learned, your mission, and cleaning up.

## Why this matters

A reverse proxy gives many internal services one public front door. It holds HTTPS in one place, spreads load over identical backends, and keeps the backend machines off the public network.

The exam asks you to put a proxy in front of an app under time pressure. Most mistakes come from three small things: the trailing slash, a forgotten `Host` header, and a reload without a test. This module trains all three.
