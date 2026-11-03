# Health Checks And Retries

Astronaut, a bay can go dark at any moment. In this part you see how the docking control tower notices a dead bay, stops sending visitors there, and tries the same visitor at another bay so they never see the failure.

## Passive health checks

The free, open source NGINX does **not** probe backends on its own. It watches real traffic instead, and only a failed request counts against a backend.

### `max_fails` and `fail_timeout`

If a request to a server fails, that counts against it. After `max_fails` failures within `fail_timeout` seconds, NGINX marks the server **unavailable** and stops sending to it for `fail_timeout` seconds. After that, it tries the server again.

```nginx
server 127.0.0.1:9002 max_fails=2 fail_timeout=15s;
```

Two things trip people up:

- `fail_timeout` is **both** the window for counting failures and the length of the break that follows. There is no separate setting for each.
- What counts as a "failure" is set by `proxy_next_upstream`. By default that is only connection errors and timeouts, *not* an HTTP 500 that the backend returns.

### Two more flags on a server line

- `backup` marks a server that gets traffic **only when every other server is unavailable**. It is a standby for an outage, not extra room for load.
- `down` takes a server out of the pool on purpose, without deleting its line.

### A backend drops out and comes back

Set `max_fails=2 fail_timeout=15s` on the `backend-2` line in `/etc/nginx/conf.d/lb.conf`, and apply it:

<!-- astrona:playground:renew -->

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Then stop that backend and run the counting loop:

```sh
sudo systemctl stop backend-2
for i in $(seq 12); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
```

After the first couple of requests hit the dead backend and fail, NGINX drops it, and the rest split over the two that are left:

```text
      6 backend : backend-1 ...
      6 backend : backend-3 ...
```

(Shortened: the backend addresses are cut.)

Now start the backend again:

```sh
sudo systemctl start backend-2
```

Wait longer than `fail_timeout` (15 seconds), and run the loop again. The requests land on all three backends: NGINX tried `backend-2` again and found it healthy. Nothing probed it in between. NGINX needed live requests to notice both the failure and the recovery.

## Retrying a failed request: `proxy_next_upstream`

When a request to one backend fails, `proxy_next_upstream` lets NGINX send the **same request** to the next server, instead of returning an error to the client. It also defines what "fails" means for the health counter above.

### What it retries, and what it must not

```nginx
location / {
    proxy_pass http://app_pool;
    proxy_next_upstream error timeout http_502;
}
```

The default is `error timeout` (plus `invalid_header`). You can add `http_500 http_502 http_503 http_504`.

What you should **not** add lightly is `non_idempotent`. Without it, NGINX does not retry a `POST`, `PATCH` or `LOCK` request once the request body has been sent, because a retry could apply the same change twice. `proxy_next_upstream_tries` and `proxy_next_upstream_timeout` limit how far the retries go.

### The client never sees the failure

In `/etc/nginx/conf.d/lb.conf`, remove the `#` in front of the `proxy_next_upstream error timeout http_502;` line in `location /` (or add the line). Apply it:

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Then stop a backend, send eight requests, and print only the status codes:

```sh
sudo systemctl stop backend-3
for i in $(seq 8); do curl -s -o /dev/null -w '%{http_code} ' http://localhost:8080/; done ; echo
sudo systemctl start backend-3
```

Every request returns `200`, even though `backend-3` is down:

```text
200 200 200 200 200 200 200 200
```

A request sent to `backend-3` failed to connect, and NGINX sent it straight on to another backend. Without `proxy_next_upstream`, some of those would have been `502`.

## Common pitfalls

> [!WARNING]
> - **Expecting active health checks.** The open source NGINX only reacts to failed live traffic (`max_fails` and `fail_timeout`). A dead backend still gets picked until enough real requests fail. Active `health_check` is an NGINX Plus feature.
> - **Reading `fail_timeout` as one thing.** It is the window for counting failures *and* the length of the break.
> - **An HTTP 500 that does not count as a failure.** Only the conditions in `proxy_next_upstream` count. By default a `500` or `503` from the backend does not mark it unhealthy. Add `http_500 http_503` if you want that.
> - **`backup` treated as extra capacity.** A `backup` server gets no traffic until *all* the other servers are unavailable. It does not help with load.
> - **Retrying requests that change data.** Adding `non_idempotent` to `proxy_next_upstream` can apply a `POST` twice. Leave it off unless the backend can safely handle the same request twice.
