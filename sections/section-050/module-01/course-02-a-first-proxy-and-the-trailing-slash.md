# A First Proxy And The Trailing Slash

Astronaut, time to give the docking control tower its first order: send every visitor who asks for `/a/` on to `backend-a`. Then you meet the single most common source of proxy confusion, the trailing slash. One `/` at the end of an address decides which path the backend sees.

## A first proxy

`proxy_pass` inside a `location` tells NGINX to forward matching requests to a backend instead of serving a file. You see it work first, then read the rule.

### Forward one path to a backend

The backend address is a scheme, a host and a port. Add this block inside the `server { … }` block in `/etc/nginx/sites-available/default`, above the existing `location /`:

<!-- astrona:playground:renew -->

```nginx
location /a/ {
    proxy_pass http://127.0.0.1:9001/;
}
```

Apply it, then send a request:

```sh
sudo nginx -t && sudo systemctl reload nginx
curl -s http://localhost/a/hello
```

The echo backend answers:

```text
backend   : backend-a (127.0.0.1:9001)
method    : GET
path      : /hello
host      : 127.0.0.1:9001
```

NGINX took the request on port 80 and made its own request to `127.0.0.1:9001`. The client never connected to port 9001. Look at `path : /hello`: the backend did not see `/a/hello`. The next section explains why.

## The trailing-slash rule

Whether the backend sees `/hello` or `/a/hello` depends on one thing: does `proxy_pass` have a **URI part**? The URI (Uniform Resource Identifier) part is anything after the host and port, even a single `/`.

### Two forms of `proxy_pass`

- **`proxy_pass http://127.0.0.1:9001/;`** has a URI part (`/`). NGINX takes the part of the request path that matched the `location` and **replaces** it with that URI. `location /a/` matched `/a/`, so `/a/hello` becomes `/hello`.
- **`proxy_pass http://127.0.0.1:9001;`** has no URI part. NGINX passes the request path **unchanged**, so `/a/hello` stays `/a/hello`.

Think of the tower's forwarding slip. With a URI part, the tower crosses out the bay name the visitor asked for and writes its own. Without one, the tower copies the visitor's request word for word.

### Try the no-slash form

Change the block to the form without the slash:

```nginx
location /a/ {
    proxy_pass http://127.0.0.1:9001;
}
```

Apply it and look only at the path the backend reports:

```sh
sudo nginx -t && sudo systemctl reload nginx
curl -s http://localhost/a/hello | grep '^path'
```

```text
path      : /a/hello
```

With the URI part (`/`) present, the backend saw `/hello`. Without it, the backend saw `/a/hello`. Pick the form that matches what the backend expects at its root.

> [!TIP]
> When a proxied page gives a `404`, first check the path the backend received. A wrong trailing slash is the most likely cause, and an echo backend or the backend's access log shows it straight away.

## Common pitfalls

> [!WARNING]
> - **The `proxy_pass` trailing slash.** `proxy_pass http://host:port/;` cuts the matched `location` prefix out of the path. `proxy_pass http://host:port;` passes the path untouched. Decide which form the backend wants, and use it the same way everywhere.
> - **Forgetting to reload.** NGINX keeps using the old configuration until you run `sudo systemctl reload nginx`.
> - **Putting the new `location` in the wrong place.** It must sit inside the `server { … }` block, not after its closing `}`. `nginx -t` reports this.
