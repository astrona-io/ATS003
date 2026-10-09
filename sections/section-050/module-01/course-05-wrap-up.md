# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module turned NGINX into a docking control tower: a reverse proxy that takes every visitor's request and forwards it to the right bay.

**From [What A Reverse Proxy Does](./course-01-what-a-reverse-proxy-does.md):**

- A reverse proxy ends the client's connection, makes its own request to the backend, and returns the answer. A forward proxy works for clients going out; a reverse proxy works for servers taking requests in.
- NGINX works at Layer 7: it reads the HTTP request, so it can route by path, host and headers.
- `nginx -t` tests the configuration, `nginx -T` prints the full configuration NGINX really uses, and `sudo systemctl reload nginx` applies it without dropping connections.
- `/etc/nginx/nginx.conf` pulls in `sites-enabled/` and `conf.d/*.conf`. The contexts nest as `http`, `server`, `location`.

**From [A First Proxy And The Trailing Slash](./course-02-a-first-proxy-and-the-trailing-slash.md):**

- `proxy_pass` inside a `location` forwards matching requests to a backend.
- `proxy_pass http://127.0.0.1:9001/;` (with a URI part) replaces the matched prefix, so `/a/hello` arrives as `/hello`.
- `proxy_pass http://127.0.0.1:9001;` (no URI part) passes the path unchanged, so `/a/hello` arrives as `/a/hello`.

**From [Headers And Location Matching](./course-03-headers-and-location-matching.md):**

- Without `proxy_set_header Host $host;` the backend sees `Host: 127.0.0.1:9001`.
- `X-Real-IP` and `X-Forwarded-For` carry the client's address. Only trust them on a hop you control.
- NGINX picks a `location` in this order: exact `=` match, then the longest prefix (final if marked `^~`), then the first matching regular expression in file order, then the remembered prefix.

**From [Upstream Pools And Failing Backends](./course-04-upstream-pools-and-failing-backends.md):**

- An `upstream` block in the `http` context names a group of backends. `proxy_pass http://app_pool/;` spreads requests over it with round-robin.
- `least_conn;` and `ip_hash;` change the method; `weight`, `max_fails`, `fail_timeout`, `backup` and `down` tune each member.
- `502 Bad Gateway` means NGINX could not reach the backend; `504 Gateway Timeout` means the backend did not answer in time. Both appear in `/var/log/nginx/error.log`.

## Your missions

You proved the skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Nginx Reverse Proxy Lab](./labs/lab-01/README.md) | Upstream Pools And Failing Backends | a fixed-target proxy on one port and a load balancer on another, with the existing apps untouched |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A request for <code>/a/hello</code> hits <code>location /a/</code> with <code>proxy_pass http://127.0.0.1:9001/;</code>. Which path does the backend see?</summary>

`/hello`. The `proxy_pass` address has a URI part (`/`), so NGINX replaces the matched prefix `/a/` with it.
</details>

<details>
<summary>2. The backend logs every request with <code>Host: 127.0.0.1:9001</code>. What is missing?</summary>

`proxy_set_header Host $host;`. Without it, NGINX sends the `proxy_pass` target as the `Host` header.
</details>

<details>
<summary>3. You have <code>location /a/</code> and <code>location ~ \.json$</code>. Which one gets <code>/a/thing.json</code>?</summary>

The regular expression block. NGINX remembers the longest prefix, then tries regular expressions in file order, and the first match wins. Mark the prefix with `^~` if it must win.
</details>

<details>
<summary>4. Which command shows the full configuration NGINX really uses, with every include filled in?</summary>

`sudo nginx -T` (capital T). Small `-t` only tests it.
</details>

<details>
<summary>5. A proxied page returns <code>502</code>. Where do you look first?</summary>

At the backend and the link to it: is the backend running and listening on the address in `proxy_pass`? `/var/log/nginx/error.log` shows the backend address NGINX could not reach.
</details>

<details>
<summary>6. Where does an <code>upstream</code> block go?</summary>

In the `http` context, next to the `server` blocks, never inside a `server` block.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy nginx-proxy-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-051
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-01/playground`. It always starts clean, so nothing you broke carries over.
