# Solution Walkthrough

You will add one new nginx file with two `server` blocks — a fixed-target
proxy on `8001` and a load balancer on `8000` — then reload nginx.
Everything runs on the VM's `terminal`. You never touch the existing app
configs.

| Goal | nginx piece |
| --- | --- |
| Send a port to one backend | `location / { proxy_pass http://IP:PORT; }` |
| Force every request onto one path | `rewrite ^.*$ /special break;` before `proxy_pass` |
| Spread across backends | `upstream NAME { server …; server …; }` + `proxy_pass http://NAME;` |
| Apply changes | `sudo nginx -t` then `sudo systemctl reload nginx` |

## The feedback loop

Grading runs from the **host terminal** — the shell where you typed
`astrona run`:

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-02/lab-01
```

Four checks:

```text
PASS  existing-apps-untouched
FAIL  nginx-syntax
FAIL  proxy-8001
FAIL  loadbalancer-8000
```

(`existing-apps-untouched` passes as long as you never edit their files.)
Run the check after each step.

---

## Step 1: See what the backends serve

On the VM:

```bash
curl http://127.0.0.1:1111/
curl http://127.0.0.1:2222/
curl http://127.0.0.1:2222/special
ls /etc/nginx/conf.d/ /etc/nginx/sites-enabled/
```

You should get `app-1111-root`, `app-2222-root`, `app-2222-special`. The
existing app configs live in those directories — leave them alone.

---

## Step 2: Write the new config file

Create a fresh file (nginx automatically includes everything in
`conf.d/*.conf`):

```bash
sudo nano /etc/nginx/conf.d/lab.conf
```

Put this in it:

```nginx
upstream lab_backends {
    server 127.0.0.1:1111;
    server 127.0.0.1:2222;
}

server {
    listen 8000;
    location / {
        proxy_pass http://lab_backends;
    }
}

server {
    listen 8001;
    location / {
        rewrite ^.*$ /special break;
        proxy_pass http://127.0.0.1:2222;
    }
}
```

How the `8001` block works: `rewrite ^.*$ /special break` changes the
request path to `/special` for *any* incoming path, and `break` stops
further rewrite processing so `proxy_pass` sends exactly `/special` to the
backend. Because `proxy_pass` has no URI part of its own, it forwards the
rewritten path as-is. No `3xx` is ever sent to the client.

The `8000` block names both backends in an `upstream` and proxies to it;
nginx round-robins between them by default.

Save and exit (`nano`: `Ctrl+O`, `Enter`, `Ctrl+X`).

---

## Step 3: Test and reload

```bash
sudo nginx -t
```

If it says `syntax is ok` / `test is successful`, reload:

```bash
sudo systemctl reload nginx
```

**Run the check** — `nginx-syntax` now passes.

---

## Step 4: Verify the two ports

```bash
curl http://127.0.0.1:8001/
curl http://127.0.0.1:8001/anything-else
for i in $(seq 1 6); do curl -s http://127.0.0.1:8000/; echo; done
```

`:8001` should return `app-2222-special` for both paths. `:8000` should
alternate between `app-1111-root` and `app-2222-root`.

**Run the check** — `proxy-8001` and `loadbalancer-8000` now pass. All four
green.

---

## Step 5: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c labs/section-050/module-02/lab-01
```

---

## If a check stays red

- **`proxy-8001` fails — `/anything-else` did not return `app-2222-special`.**
  You used `proxy_pass http://127.0.0.1:2222/special;` (with a URI), which
  appends the leftover path. Use the `rewrite ^.*$ /special break;` +
  `proxy_pass http://127.0.0.1:2222;` form shown above.
- **`proxy-8001` fails — "returned HTTP 301".** You used `return 301` or
  `rewrite … redirect`/`permanent`. Use `break`, not a redirect.
- **`loadbalancer-8000` fails — only one backend seen.** Both `server`
  lines must be inside one `upstream` block, and `proxy_pass` must point at
  that upstream name.
- **`nginx-syntax` fails.** A missing `;` or unbalanced `{ }`. `sudo nginx
  -t` prints the file and line.
- **`existing-apps-untouched` fails.** You edited a `1111` / `2222` config.
  Revert it; all your rules belong in the new `lab.conf` only.
