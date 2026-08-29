# Overview: PLAYGROUND — Nginx Reverse Proxy (Playground)

> Declared in [`../config.yaml`](../config.yaml) under `metadata.docs.guide`.

This is a **playground**, not a lab. The environment starts clean, runs
`bootstrap/prepare.sh`, and then waits. There is no task, no `astrona submit`,
and no pass/fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single qemu VM — a plain Ubuntu 24.04 server. Reach it with
  `astrona ssh nginx-proxy-playground`.
- **nginx**, serving its stock default page on port 80. No proxy config yet.
- **Two backend apps** that echo what they receive, as plain text:
  - `backend-a` on `127.0.0.1:9001`
  - `backend-b` on `127.0.0.1:9002`
  - Each reply prints the method, the exact `path` it was asked for, and the
    `Host`, `X-Forwarded-For`, `X-Real-IP`, `X-Forwarded-Proto` headers it saw.
- `curl` and `python3`. Password-less `sudo`.

Edit config under `/etc/nginx/` — the simplest place is
`/etc/nginx/sites-available/default` (already symlinked into `sites-enabled/`),
or drop a `*.conf` file in `/etc/nginx/conf.d/`. After every change:

```sh
sudo nginx -t && sudo systemctl reload nginx
```

## Things to try

- **A first proxy.** Inside the `server { … }` block add:
  ```nginx
  location /a/ { proxy_pass http://127.0.0.1:9001/; }
  ```
  reload, then `curl -s http://localhost/a/hello`. Look at the `path` the
  backend reports.
- **The trailing-slash rule.** Compare `proxy_pass http://127.0.0.1:9001/;`
  with `proxy_pass http://127.0.0.1:9001;` (no path, no slash) for the same
  `location /a/`. Watch how `/a/hello` arrives at the backend as `/hello`
  versus `/a/hello`.
- **Forward the real Host.** Without `proxy_set_header Host $host;` the backend
  sees `Host: 127.0.0.1:9001`. Add it and the backend sees the name the client
  used.
- **Client IP.** Add `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`
  and `proxy_set_header X-Real-IP $remote_addr;`, reload, and see them appear in
  the echo.
- **An upstream pool.** Define
  ```nginx
  upstream app { server 127.0.0.1:9001; server 127.0.0.1:9002; }
  ```
  point `proxy_pass http://app;` at it, and run `curl` several times — the
  `backend` line alternates a/b (round-robin).
- **Location matching.** Try `location = /exact`, `location /prefix/`, and
  `location ~ \.json$` together and see which one wins for a given URL
  (`nginx` prefers exact, then longest prefix, then regex in file order).
- **A dead backend.** `sudo systemctl stop backend-b`, then `curl` a location
  pointed at `:9002` — nginx returns `502 Bad Gateway`. Check
  `/var/log/nginx/error.log`. Start it again with `sudo systemctl start backend-b`.
- **Headers from the other side.** `curl -sI http://localhost/a/hello` to see
  the response headers nginx adds (`Server: nginx/…`).

## What this sandbox does not set up

- **TLS.** Port 80 only; no certificates. `proxy_pass` here is plain HTTP to
  localhost.
- **Real separate backend hosts.** The "backends" are two local processes.
- **A real client.** Requests come from `curl` on the same VM, so
  `X-Forwarded-For` will show `127.0.0.1`.
- **Anything to grade.**

## When you're done

```sh
astrona destroy nginx-proxy-playground
```

(`astrona destroy` takes the environment name, not the config path.)
