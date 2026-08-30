# Nginx Load Balancers

<!-- astrona:playground -->
> [!NOTE]
> 🧪 **Hands-on playground for this module** — a clean, throwaway machine to explore on. No task, no grading. Folder: [`playground/`](https://github.com/astrona-io/ATS003/tree/main/sections/section-050/module-02/playground)
>
> ```sh
> astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-02/playground
> astrona destroy nginx-lb-playground
> ```

A reverse proxy in front of **one** backend routes traffic. A reverse proxy in front of **several identical backends** also spreads the load and rides out a backend failure — that is **load balancing**. In nginx it is the same `proxy_pass`, pointed at a named pool instead of a single address.

The pool is an `upstream` block, declared in the `http { }` context (alongside, not inside, a `server` block):

```nginx
upstream app_pool {
    server 127.0.0.1:9001;
    server 127.0.0.1:9002;
    server 127.0.0.1:9003;
}

server {
    location / {
        proxy_pass http://app_pool;
    }
}
```

Every request to that `location` now goes to one of the three backends. This module is about the two decisions that shape how: **which method** picks the backend, and **what happens when one is unhealthy**.

## Learning objectives

After this module you can:

- Define an `upstream` pool and point a proxied `location` at it.
- Choose a balancing method — weighted round-robin, `least_conn`, `hash` / `ip_hash` — and explain when each fits.
- Set `weight`, `backup`, and `down` on a pool member and predict the traffic split.
- Explain nginx's passive health checking (`max_fails`, `fail_timeout`) and how it differs from active probing.
- Configure `proxy_next_upstream` to retry a failed request on another backend, and say why `POST`s are excluded by default.
- Diagnose uneven or stuck distribution back to the method and the client's address.

## Before you start

This module follows the **reverse proxy** module — `proxy_pass`, `location` blocks, `proxy_set_header`, and `nginx -t && systemctl reload nginx` are used here without re-explaining. You should be able to open a shell, use `sudo`, and edit a text file.

Open a shell on the playground VM with `astrona ssh astro-nginx-lb-playground`. It has:

- nginx serving its default page on port 80, and a **working round-robin load balancer on port 8080**, defined in `/etc/nginx/conf.d/lb.conf`.
- `upstream app_pool` over **three echo backends** — `backend-1` / `backend-2` / `backend-3` on `127.0.0.1:9001` / `:9002` / `:9003`. Each reply names the backend that produced it. They accept `?ms=N` to reply after an N-millisecond delay.

Edit `/etc/nginx/conf.d/lb.conf`, then `sudo nginx -t && sudo systemctl reload nginx`. `curl` runs on this VM, so every request carries the same client IP — which matters for `ip_hash`. No TLS, and this is nginx open source, so the `health_check` and `slow_start` directives (nginx Plus) are not available.

## Where this fits

This is **Layer 7** load balancing — nginx reads each HTTP request and can pick a backend based on the URL, a header, or a cookie. A **Layer 4** balancer (nginx's own `stream {}` module, HAProxy in TCP mode, a cloud load balancer) forwards raw TCP without parsing it: less flexible, less overhead, and it works for non-HTTP protocols.

Two design points the directives do not enforce. The backends in a pool must be **interchangeable** — if a user's session lives in one backend's memory, plain round-robin will log them out on the next request; you need `ip_hash`/`hash` stickiness or, better, a shared session store so the backends are truly stateless. And the load balancer itself is now a **single point of failure**: production setups run two, with a floating IP (keepalived), DNS, or anycast in front. The `proxy_set_header Host` / `X-Forwarded-For` lines from the reverse-proxy module still apply to every backend here.

## Round-robin, the default

With no method directive, nginx uses **weighted round-robin**: it hands out requests to each server in turn. A `weight=N` on a server multiplies its share — `weight=3` means that server is chosen three times per one time a `weight=1` server is.

> [!TIP]
> **Try it — the even baseline**
>
> ```sh
> for i in $(seq 12); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
> ```
>
> Expect an even split across the three:
>
> ```text
>       4 backend : backend-1 (127.0.0.1:9001)
>       4 backend : backend-2 (127.0.0.1:9002)
>       4 backend : backend-3 (127.0.0.1:9003)
> ```
>
> Twelve requests, four each — plain round-robin. This is the distribution every other method is a change from.

## Weighting a server

When backends are not equal — one host has more CPU, or you are shifting traffic onto a new machine gradually — `weight` changes the ratio without changing the rotation.

> [!TIP]
> **Try it — give one backend a bigger share**
>
> In `lb.conf`, change the first line of the pool to `server 127.0.0.1:9001 weight=3;`, then `sudo nginx -t && sudo systemctl reload nginx` and re-run the loop with more requests:
>
> ```sh
> for i in $(seq 15); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
> ```
>
> Expect roughly a 3 : 1 : 1 split:
>
> ```text
>       9 backend : backend-1 ...
>       3 backend : backend-2 ...
>       3 backend : backend-3 ...
> ```
>
> `backend-1` took three shares to the others' one each. Set the weight back to `1` (or remove it) before the next section.

## `least_conn`: follow the load, not the count

Round-robin assumes every request costs the same. When they do not — some requests are slow, some quick — a backend can pile up slow requests while its turn keeps coming. `least_conn;` in the `upstream` block sends each new request to the server with the **fewest active connections** right now.

The echo backends take `?ms=N` so you can create slow requests on demand.

> [!TIP]
> **Try it — new requests avoid the busy backend**
>
> Add `least_conn;` as the first line inside `upstream app_pool { … }`, reload, then fire several slow requests in the background and a few fast ones on top:
>
> ```sh
> for i in $(seq 3); do curl -s "http://localhost:8080/?ms=1500" & done
> sleep 0.3
> for i in $(seq 6); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
> ```
>
> The fast requests avoid whichever backends are still holding a slow one:
>
> ```text
>       3 backend : backend-2 ...
>       3 backend : backend-3 ...
> ```
>
> With round-robin, two of the fast six would have queued behind a 1.5-second request on `backend-1`. `least_conn` routed around it. Remove `least_conn;` again afterwards.

## Hashing: sending related requests to the same backend

Sometimes you want a given client — or a given URL, or a session — to keep landing on the **same** backend, for a warm cache or in-memory state. Two directives do this by hashing a key to a server:

- `ip_hash;` — keys on the client IP. Simple stickiness, but if clients arrive through another proxy or a CDN they may all share one address and all land on one backend.
- `hash <key> [consistent];` — keys on any variable you name, such as `hash $request_uri consistent;`. `consistent` uses a ketama ring so adding or removing a backend reshuffles only a fraction of keys instead of all of them.

Because `curl` here always comes from `127.0.0.1`, `ip_hash` would send *every* request to one backend — good to see once, but `hash $request_uri` shows the spread better.

> [!TIP]
> **Try it — each path sticks to one backend**
>
> Put `hash $request_uri consistent;` as the first line of the `upstream` block, reload, then request three paths a few times each:
>
> ```sh
> for p in /alpha /beta /gamma; do
>   for i in 1 2 3; do curl -s "http://localhost:8080$p" | grep '^backend'; done
>   echo ---
> done
> ```
>
> Expect each path pinned to one backend, but different paths on different ones:
>
> ```text
> backend : backend-3 ...
> backend : backend-3 ...
> backend : backend-3 ...
> ---
> backend : backend-1 ...
> ...
> ```
>
> Every `/alpha` went to the same backend; `/beta` and `/gamma` to others. Distribution is by key, not round-robin — so an uneven key mix gives an uneven load. Restore the plain pool afterwards.

## Passive health checks

nginx open source does **not** actively probe backends. Instead it watches real traffic: if a request to a server fails, that counts against it, and after `max_fails` failures within `fail_timeout` seconds nginx marks the server **unavailable** and stops sending to it — for `fail_timeout` seconds, after which it tries again.

```nginx
server 127.0.0.1:9002 max_fails=2 fail_timeout=15s;
```

Two things trip people up. First, `fail_timeout` is **both** the window for counting failures and the length of the timeout that follows. Second, what counts as a "failure" is set by `proxy_next_upstream` (next section) — by default only connection errors and timeouts, *not* an HTTP 500 the backend returns.

Two more per-server flags:

- `backup` — a server that receives traffic **only when every non-backup server is unavailable**. Not a spillover for load, a standby for outage.
- `down` — administratively removed from the pool, without deleting the line.

> [!TIP]
> **Try it — a backend drops out and comes back**
>
> Set `max_fails=2 fail_timeout=15s` on the `backend-2` line, reload, then stop that backend and watch the loop:
>
> ```sh
> sudo systemctl stop backend-2
> for i in $(seq 12); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
> ```
>
> After the first couple of requests hit the dead backend and fail, it is dropped and the rest split across the survivors:
>
> ```text
>       6 backend : backend-1 ...
>       6 backend : backend-3 ...
> ```
>
> Now `sudo systemctl start backend-2`, wait past `fail_timeout` (15s), and the loop again lands on all three — nginx retried it and found it healthy. Nothing probed it in between; it took live requests to notice both the failure and the recovery.

## Retrying a failed request: `proxy_next_upstream`

When a request to one backend fails, `proxy_next_upstream` lets nginx try the **same request** on the next server rather than returning an error to the client. It also defines what "fails" means for the health counter above.

```nginx
location / {
    proxy_pass http://app_pool;
    proxy_next_upstream error timeout http_502;
}
```

The default is `error timeout` (plus `invalid_header`). You can add `http_500 http_502 http_503 http_504`. What you should **not** add lightly is `non_idempotent`: without it, nginx will not retry a `POST`/`PATCH`/`LOCK` once the request body has been sent, because retrying could apply the same change twice. `proxy_next_upstream_tries` and `proxy_next_upstream_timeout` bound how far it will go.

> [!TIP]
> **Try it — the client never sees the failure**
>
> Uncomment (or add) `proxy_next_upstream error timeout http_502;` in `location /`, reload, then stop a backend and watch the status codes:
>
> ```sh
> sudo systemctl stop backend-3
> for i in $(seq 8); do curl -s -o /dev/null -w '%{http_code} ' http://localhost:8080/; done ; echo
> sudo systemctl start backend-3
> ```
>
> Expect all `200`s, even though `backend-3` is down:
>
> ```text
> 200 200 200 200 200 200 200 200
> ```
>
> A request routed to `backend-3` failed to connect, and nginx immediately re-sent it to another backend. Without `proxy_next_upstream`, some of those would have been `502`.

> [!WARNING]
> **Common pitfalls**
>
> - **Expecting active health checks.** nginx open source only reacts to failed live traffic (`max_fails` / `fail_timeout`). A backend can be down and still get picked until enough real requests fail, and it is retried automatically once `fail_timeout` passes. Active `health_check` is nginx Plus.
> - **`fail_timeout` misread as one thing.** It is the failure-counting window *and* the eviction duration. There is no separate knob for each.
> - **An HTTP 500 not counting as a failure.** Only the conditions in `proxy_next_upstream` count. By default a `500`/`503` from the backend does not mark it unhealthy — add `http_500 http_503` if you want that.
> - **`ip_hash` behind a proxy or CDN.** Every client then shares the proxy's IP, so they all hash to one backend. Use `hash` on a better key, or real sticky cookies.
> - **`backup` treated as spillover.** A `backup` server gets zero traffic until *all* primaries are unavailable. It does not help with load.
> - **Retrying non-idempotent requests.** Adding `non_idempotent` to `proxy_next_upstream` can double-apply a `POST`. Leave it off unless the backend is idempotent.
> - **Stateful backends with round-robin.** If a session is held in one backend's memory, spreading requests breaks it. Make backends stateless or add stickiness deliberately.
