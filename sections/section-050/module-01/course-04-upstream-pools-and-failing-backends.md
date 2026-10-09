# Upstream Pools And Failing Backends

Astronaut, one bay behind the docking control tower is a single point of failure. In this part you give the tower a group of bays, so it can share visitors between them. Then you switch one bay off on purpose and read the error the tower sends back.

## Load balancing with `upstream`

An `upstream` block names a group of backend servers: the bays behind the tower. Point `proxy_pass` at the group's name, and NGINX spreads requests over its members.

### The pool and the default rotation

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

The `upstream` block sits in the `http` context, next to the `server` block, not inside it. By default NGINX uses **weighted round-robin**: it hands requests to each member in turn.

Other methods are one line inside the `upstream` block: `least_conn;` sends each request to the member with the fewest active connections, and `ip_hash;` always sends the same client to the same member. Each `server` line also takes options such as `weight=3`, `max_fails=2 fail_timeout=30s`, `backup` and `down`.

Host names are looked up once. A plain host name in `proxy_pass` or in an `upstream` `server` line is turned into an address when NGINX starts or reloads. If the backend's address changes later, NGINX does not notice until the next reload, unless you use a `resolver` with a variable in `proxy_pass`.

### See requests alternate

Add the `upstream app_pool` block above to the top of `/etc/nginx/sites-available/default`, outside the `server` block. Add the `location /app/` block inside the `server` block. Then apply it:

<!-- astrona:playground:renew -->

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Send four requests and look only at the backend line:

```sh
for i in 1 2 3 4; do curl -s http://localhost/app/ | grep '^backend'; done
```

```text
backend   : backend-a (127.0.0.1:9001)
backend   : backend-b (127.0.0.1:9002)
backend   : backend-a (127.0.0.1:9001)
backend   : backend-b (127.0.0.1:9002)
```

Two backends, round-robin. Add a third `server` line, and it joins the rotation after the next reload.

## When the backend fails

The tower can only forward a visitor if the bay answers. NGINX tells you clearly when it does not, and the status code tells you which kind of failure it was.

### `502` and `504`

- **502 Bad Gateway:** NGINX cannot reach the backend. The connection was refused or reset, or the process is gone.
- **504 Gateway Timeout:** the backend took the connection but did not answer in time. The limit is `proxy_read_timeout`, 60 seconds by default.

NGINX writes both to `/var/log/nginx/error.log`, together with the backend address.

### Stop a backend and see the 502

Stop `backend-b`, send two requests, and read the error log:

```sh
sudo systemctl stop backend-b
curl -s -o /dev/null -w '%{http_code}\n' http://localhost/app/
curl -s -o /dev/null -w '%{http_code}\n' http://localhost/app/
sudo tail -n 2 /var/log/nginx/error.log
```

With `backend-b` down, the round-robin still tries it, and some requests fail:

```text
200
502
```

```text
... connect() failed (111: Connection refused) while connecting to upstream,
    ... upstream: "http://127.0.0.1:9002/"
```

(The log line is shortened.)

`502` means "I am the proxy, and I could not get an answer from the backend". That is a different problem from a `404` that the backend itself returns. Start the backend again:

```sh
sudo systemctl start backend-b
```

> [!TIP]
> Read the status code before you debug. A `502` or `504` points at the link between NGINX and the backend. A `404` or `500` came from the backend itself, so look at the backend.

## Common pitfalls

> [!WARNING]
> - **Putting `upstream` inside `server`.** The `upstream` block belongs in the `http` context, beside the `server` blocks. `nginx -t` rejects it in the wrong place.
> - **`proxy_pass` pointing at an address instead of the pool.** Requests only spread out when `proxy_pass` names the `upstream` group, for example `http://app_pool/`.
> - **Host names looked up once.** A host name in `proxy_pass` or `upstream` is turned into an address at start or reload. A changed backend address goes unnoticed until the next reload.
> - **Reading a `502` as a backend bug.** It means NGINX could not reach the backend at all. Check that the backend is running and listening on the right port.

## Your mission: Nginx Reverse Proxy Lab

You can now forward paths to a backend, control the path it sees, and spread requests over an `upstream` pool. The mission asks you to put two new front-end ports in place with NGINX: one that sends every path to one fixed backend page, and one that balances over two apps, without touching the apps that already run.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop nginx-proxy-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-01/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-050/module-01/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-051
astrona start nginx-proxy-playground
```
