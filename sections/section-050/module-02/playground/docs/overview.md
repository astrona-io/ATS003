# Overview: PLAYGROUND — Nginx Load Balancers (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh nginx-lb-playground`.
- **nginx**: the stock default page on port 80, and a **load balancer on port
  8080** defined in `/etc/nginx/conf.d/lb.conf`.
- **Three echo backends** on `127.0.0.1:9001` / `:9002` / `:9003`, naming
  themselves `backend-1` / `backend-2` / `backend-3` in every reply. They accept
  `?ms=N` to respond after an N-millisecond delay (for `least_conn` and timeout
  tests).
- The base `upstream app_pool` is plain round-robin across all three.
- `curl`, `python3`, password-less `sudo`.

Change the LB by editing `/etc/nginx/conf.d/lb.conf`, then:

```sh
sudo nginx -t && sudo systemctl reload nginx
```

A quick way to see the spread:

```sh
for i in $(seq 12); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
```

## Things to try

- **Plain round-robin.** The 12-request loop above lands 4 / 4 / 4.
- **Weights.** `server 127.0.0.1:9001 weight=3;` — that backend now takes ~3x
  the share.
- **`least_conn`.** Add `least_conn;` in the `upstream` block. Fire slow
  requests at it: `for i in $(seq 6); do curl -s "http://localhost:8080/?ms=800" & done` —
  new requests go to whichever backend has the fewest in flight.
- **`ip_hash` / `hash`.** `ip_hash;` sends *every* request from one client IP to
  the *same* backend — from this VM that means all to one. `hash $request_uri
  consistent;` instead spreads by URL: `curl .../a`, `.../b`, `.../c` land on
  different backends, but each path is sticky.
- **Eject an unhealthy backend.** `server 127.0.0.1:9002 max_fails=2
  fail_timeout=15s;`, reload, then `sudo systemctl stop backend-2`. After 2
  failed picks nginx stops sending to it for 15s; `sudo systemctl start
  backend-2` and it rejoins.
- **A backup server.** `server 127.0.0.1:9003 backup;` — it gets no traffic
  until *both* others are down.
- **Mark one down.** `server 127.0.0.1:9001 down;` — taken out of rotation
  without deleting the line.
- **Retry on failure.** Uncomment `proxy_next_upstream error timeout http_502;`
  in `location /`. Stop a backend and watch requests still succeed — nginx
  retries the next server in the pool.
- **Watch it live.** In one shell:
  `while :; do curl -s http://localhost:8080/ | grep '^backend'; sleep 0.3; done`
  while you stop and start backends in another.

## What this sandbox does not set up

- **Active health checks** (`health_check`) and `slow_start` — nginx open source
  has only *passive* checks (`max_fails`). Those directives need nginx Plus.
- **TLS**, real separate hosts, or a real remote client (so `ip_hash` sees only
  `127.0.0.1`).
- **Anything to grade.**

## When you're done

```sh
astrona destroy nginx-lb-playground
```

(`astrona destroy` takes the environment name, not the config path.)
