# Nginx Reverse Proxy

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-050/module-01/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-01/playground
> astrona destroy nginx-proxy-playground
> ```

A **reverse proxy** is a server that takes requests from clients and, instead of
answering them itself, makes its *own* request to a backend server and returns
that response. The client only ever talks to the proxy; it never sees the
backend, and often does not know one exists.

This is not packet forwarding. nginx **terminates** the client's TCP connection,
reads the full HTTP request, and opens a **separate** connection to the backend
to send a request it composes. That is what lets it route by URL, rewrite paths
and headers, balance across several backends, cache, and hold TLS at the edge
while the backend speaks plain HTTP.

One distinction to fix early:

- A **forward proxy** acts on behalf of *clients* — outbound, e.g. a corporate
  web filter.
- A **reverse proxy** acts on behalf of *servers* — inbound. nginx here is a
  reverse proxy.

Reverse proxies are used to give many internal services one public entry point,
to terminate HTTPS in one place, to spread load across identical backends, and
to keep backend hosts off the public network entirely.

## Learning objectives

After this module you can:

- Explain what a reverse proxy does — terminate the client connection, make its
  own backend request, return the response — and how it differs from a forward
  proxy.
- Locate nginx configuration (`nginx.conf`, `sites-enabled/`, `conf.d/`) and
  place a `proxy_pass` inside a `server` / `location` block.
- Predict how a `proxy_pass` URI and its trailing slash rewrite the path sent to
  the backend.
- Forward the client's `Host` and IP address with `proxy_set_header`, and
  explain why the backend needs them.
- Define an `upstream` group and describe nginx's default round-robin balancing.
- Diagnose a `502` or `504` from a proxied location using the response and
  `error.log`.

## Before you start

This module assumes you can open a shell, use `sudo`, edit a text file, and know
that an HTTP request carries a method, a path, and headers. `curl` is used
throughout. The DNS and firewall modules are useful background but not required.

The playground is a single VM (`astrona ssh nginx-proxy-playground`) with:

- **nginx** serving its default page on port 80, with **no proxy config** — you
  write it.
- **Two backend apps** that echo what they receive as plain text —
  `backend-a` on `127.0.0.1:9001`, `backend-b` on `127.0.0.1:9002`. Each reply
  prints the method, the exact `path` it was asked for, and the `Host` /
  `X-Forwarded-For` / `X-Real-IP` headers it saw.

Edit `/etc/nginx/sites-available/default` (already enabled) or add a file under
`/etc/nginx/conf.d/`, then apply with `sudo nginx -t && sudo systemctl reload
nginx`. `curl` runs on the same VM, so `X-Forwarded-For` will show `127.0.0.1`.
No TLS — port 80 only. `sudo` needs no password.

## Where nginx configuration lives

nginx reads `/etc/nginx/nginx.conf`, which on Debian and Ubuntu pulls in every
file under `sites-enabled/` and every `*.conf` under `conf.d/`. Inside is a tree:

```text
http {
    server {              # one virtual host: listen + server_name
        location /path/ {  # a rule matched against the request URI
            ...
        }
    }
}
```

A `server` block is selected by `listen` and `server_name`; a `location` block
within it is selected by matching the request path. `nginx -T` prints the whole
effective configuration with every include expanded.

> [!TIP]
> **Try it — the default server, before any proxying**
>
> ```sh
> curl -s http://localhost/ | head -n 4
> sudo nginx -T | grep -nE 'listen|server_name|location|root'
> ```
>
> Expect the stock nginx page and the one `server` block that serves it:
>
> ```text
> <!DOCTYPE html>
> <html>
> <head>
> <title>Welcome to nginx!</title>
> ```
>
> ```text
> listen 80 default_server;
> root /var/www/html;
> location / {
> ```
>
> Right now `location /` just serves files from `/var/www/html`. Turning this
> into a proxy means replacing what a `location` does with `proxy_pass`.

## A first proxy

`proxy_pass` inside a `location` tells nginx to forward matching requests to a
backend instead of serving a file. The backend address is a scheme, host, and
port:

```nginx
location /a/ {
    proxy_pass http://127.0.0.1:9001/;
}
```

Add that inside the `server { … }` block in
`/etc/nginx/sites-available/default`, above the existing `location /`.

> [!TIP]
> **Try it — forward one path to a backend**
>
> After adding the block:
>
> ```sh
> sudo nginx -t && sudo systemctl reload nginx
> curl -s http://localhost/a/hello
> ```
>
> Expect the echo backend to answer:
>
> ```text
> backend   : backend-a (127.0.0.1:9001)
> method    : GET
> path      : /hello
> host      : 127.0.0.1:9001
> ```
>
> nginx accepted the request on port 80 and made its own request to
> `127.0.0.1:9001`. The client never connected to `:9001`. Note `path : /hello`,
> not `/a/hello` — the next section is about why.

## The trailing-slash rule

This is the single most common source of proxy confusion. It comes down to
whether `proxy_pass` has a **URI part** (anything after the host:port, including
a bare `/`):

- **`proxy_pass http://127.0.0.1:9001/;`** — has a URI (`/`). nginx takes the
  part of the request path that matched the `location` and **replaces** it with
  that URI. `location /a/` matched `/a/`, so `/a/hello` → `/hello`.
- **`proxy_pass http://127.0.0.1:9001;`** — no URI. nginx passes the request
  path **unchanged**. `/a/hello` → `/a/hello`.

> [!TIP]
> **Try it — the same location, two `proxy_pass` forms**
>
> Change the block to the no-slash form and reload:
>
> ```nginx
> location /a/ {
>     proxy_pass http://127.0.0.1:9001;
> }
> ```
>
> ```sh
> sudo nginx -t && sudo systemctl reload nginx
> curl -s http://localhost/a/hello | grep '^path'
> ```
>
> Expect:
>
> ```text
> path      : /a/hello
> ```
>
> With the URI (`/`) present, the backend saw `/hello`; without it, `/a/hello`.
> Pick the form that matches what the backend expects at its root.

## Passing the client's Host and IP

By default nginx sends the backend a `Host` header equal to the `proxy_pass`
target (`127.0.0.1:9001` above), not the name the client used. A backend that
serves multiple sites, builds absolute URLs, or logs the requested host needs
the original. It also sees nginx's own address as the connecting client, so the
real client IP has to be forwarded in a header the backend agrees to read.

The usual set of `proxy_set_header` lines:

```nginx
location /a/ {
    proxy_pass http://127.0.0.1:9001/;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

> [!TIP]
> **Try it — before and after the header lines**
>
> With just `proxy_pass` (no `proxy_set_header`), `curl` with an explicit Host
> and read the echo:
>
> ```sh
> curl -s -H 'Host: shop.example' http://localhost/a/hello | grep -E '^host|^x-'
> ```
>
> Expect the backend to see nginx's target, not `shop.example`, and no
> forwarding headers:
>
> ```text
> host      : 127.0.0.1:9001
> ```
>
> Now add the four `proxy_set_header` lines above, reload, and repeat the
> `curl`. This time:
>
> ```text
> host      : shop.example
> x-real-ip : 127.0.0.1
> x-forwarded-for: 127.0.0.1
> x-forwarded-proto: http
> ```
>
> `$host` carried the client's Host through; `$remote_addr` is the client IP as
> nginx sees it (here `127.0.0.1`, since `curl` is local).

## How nginx picks a `location`

When several `location` blocks could match a request, nginx does **not** just
take the first. The order is:

1. An exact match — `location = /health` — wins immediately.
2. Otherwise, the **longest matching prefix** is remembered.
3. If that prefix block is marked `^~`, it is used and matching stops.
4. Otherwise, regex blocks (`location ~ \.json$`, `~*` for case-insensitive) are
   tried **in file order**; the first to match wins.
5. If no regex matched, the remembered longest prefix is used.

The surprise for beginners: a regex block beats a longer prefix block unless the
prefix uses `^~`.

> [!TIP]
> **Try it — watch a regex beat a prefix**
>
> Add these three blocks inside the `server`, then reload:
>
> ```nginx
> location = /a/exact { proxy_pass http://127.0.0.1:9001/exact-hit; }
> location /a/        { proxy_pass http://127.0.0.1:9001/prefix-hit; }
> location ~ /a/.*\.json$ { proxy_pass http://127.0.0.1:9002/regex-hit; }
> ```
>
> ```sh
> curl -s http://localhost/a/exact       | grep -E '^backend|^path'
> curl -s http://localhost/a/thing       | grep -E '^backend|^path'
> curl -s http://localhost/a/thing.json  | grep -E '^backend|^path'
> ```
>
> Expect the exact match, the prefix, then the regex — the last one going to
> `backend-b`:
>
> ```text
> backend   : backend-a ...   path : /exact-hit
> backend   : backend-a ...   path : /prefix-hit
> backend   : backend-b ...   path : /regex-hit
> ```
>
> `/a/thing.json` matched the `/a/` prefix too, but the regex was tried after
> the prefix was remembered and won.

## Load balancing with `upstream`

An `upstream` block names a group of backend servers. Point `proxy_pass` at the
group name and nginx spreads requests across its members — by default
**weighted round-robin**, one after another.

```nginx
upstream app_pool {
    server 127.0.0.1:9001;
    server 127.0.0.1:9002;
}
server {
    # ...
    location /app/ {
        proxy_pass http://app_pool/;
    }
}
```

Other policies are one line inside the block: `least_conn;` (fewest active
connections), `ip_hash;` (same client always to the same backend). Per-server
options include `weight=3`, `max_fails=2 fail_timeout=30s`, `backup`, `down`.

> [!TIP]
> **Try it — requests alternate between backends**
>
> With the `upstream` block added and `location /app/` pointed at it:
>
> ```sh
> for i in 1 2 3 4; do curl -s http://localhost/app/ | grep '^backend'; done
> ```
>
> Expect the backend to alternate:
>
> ```text
> backend   : backend-a (127.0.0.1:9001)
> backend   : backend-b (127.0.0.1:9002)
> backend   : backend-a (127.0.0.1:9001)
> backend   : backend-b (127.0.0.1:9002)
> ```
>
> Two backends, round-robin. Add a third `server` line and it joins the
> rotation on the next reload.

## When the backend fails

If nginx cannot reach the backend — connection refused, reset, or the process
gone — it returns **502 Bad Gateway**. If the backend accepts the connection but
does not respond in time (`proxy_read_timeout`, default 60s), it returns **504
Gateway Timeout**. Both are logged in `/var/log/nginx/error.log` with the
upstream address.

> [!TIP]
> **Try it — stop a backend and see the 502**
>
> ```sh
> sudo systemctl stop backend-b
> curl -s -o /dev/null -w '%{http_code}\n' http://localhost/app/
> curl -s -o /dev/null -w '%{http_code}\n' http://localhost/app/
> sudo tail -n 2 /var/log/nginx/error.log
> ```
>
> With `backend-b` down, the round-robin still tries it and some requests fail:
>
> ```text
> 200
> 502
> ```
>
> ```text
> ... connect() failed (111: Connection refused) while connecting to upstream,
>     ... upstream: "http://127.0.0.1:9002/"
> ```
>
> `502` means "I am the proxy and I could not get an answer from the backend" —
> a different problem from a `404` the backend itself returns. Restart it with
> `sudo systemctl start backend-b`.

## Where this fits

A reverse proxy is the edge layer: it faces the network, and the application
servers sit behind it, often bound only to `127.0.0.1` or a private segment so
they cannot be reached directly. That pairs with the firewall modules — expose
80/443 on the proxy, nothing on the backends — and with DNS, where the public
name's `A` record points at the proxy, not the app. nginx here works at
**Layer 7**: it parses HTTP and can route on path, host, and headers. A
Layer-4 load balancer (nginx's own `stream {}` module, HAProxy in TCP mode, a
cloud LB) forwards raw TCP without reading it — faster, but no path routing.

The next concern once proxying works is usually TLS termination — accepting
HTTPS on the proxy and speaking HTTP to the backend — which reuses everything
here plus a `listen 443 ssl` block and certificates.

> [!WARNING]
> **Common pitfalls**
>
> - **The `proxy_pass` trailing slash.** `proxy_pass http://host:port/;` rewrites
>   the matched `location` prefix out of the path; `proxy_pass http://host:port;`
>   passes the path untouched. Decide which the backend wants and be consistent.
> - **Forgetting `proxy_set_header Host $host;`.** The backend receives
>   `Host: 127.0.0.1:9001`, which breaks name-based vhosts, redirects, and logs.
> - **Editing config without `nginx -t`.** A syntax error makes `systemctl
>   reload` fail and, on some setups, the old config keep running silently.
>   Always test first.
> - **Trusting `X-Forwarded-For` blindly.** It is just a header — a client can
>   send a fake one. Only believe it on the hop you control, and configure the
>   backend (or nginx's `real_ip` module) to trust the proxy's address only.
> - **A regex `location` beating a longer prefix.** Unless the prefix block uses
>   `^~`, regex blocks are tried after it and can win. Check the match order
>   when a request goes somewhere unexpected.
> - **Hostnames resolved once.** A plain hostname in `proxy_pass` or an
>   `upstream` `server` is resolved when nginx starts or reloads. If the backend
>   IP changes, nginx does not notice until the next reload (or you use a
>   `resolver` with a variable in `proxy_pass`).
> - **Editing `sites-available` without enabling it.** The file only takes
>   effect once it is symlinked into `sites-enabled/`.
