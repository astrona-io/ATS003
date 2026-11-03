# Solution Walkthrough

You add one new NGINX file with two `server` blocks, a fixed-target proxy on `8001` and a load balancer on `8000`, then reload NGINX. Everything runs in the training ship's `terminal`. You never touch the existing app files.

NGINX plays the docking control tower here: visitors call the tower on a port, and the tower forwards them to the right bay (backend).

| Goal | NGINX piece |
| --- | --- |
| Send a port to one backend | `location / { proxy_pass http://IP:PORT; }` |
| Force every request onto one path | `rewrite ^.*$ /special break;` before `proxy_pass` |
| Spread across backends | `upstream NAME { server …; server …; }` + `proxy_pass http://NAME;` |
| Apply changes | `sudo nginx -t` then `sudo systemctl reload nginx` |

## The feedback loop

Grading runs from the **host terminal**: the shell where you typed `astrona run`, not inside the training ship.

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-01/labs/lab-01
```

Before you start, the grader reports four checks:

```text
PASS  existing-apps-untouched
FAIL  nginx-syntax
FAIL  proxy-8001
FAIL  loadbalancer-8000
```

`existing-apps-untouched` passes as long as you never edit the apps' files. Run the check after each step.

---

## Step 1: See what the backends serve

On the training ship, ask each app for its pages and list the configuration folders:

```bash
curl http://127.0.0.1:1111/
curl http://127.0.0.1:2222/
curl http://127.0.0.1:2222/special
ls /etc/nginx/conf.d/ /etc/nginx/sites-enabled/
```

You get `app-1111-root`, `app-2222-root` and `app-2222-special`. The existing app files live in those folders. Leave them alone.

---

## Step 2: Write the new configuration file

NGINX automatically reads every `*.conf` file in `/etc/nginx/conf.d/`, so a fresh file there is all you need. Open it with `sudo` in your editor (for example `sudo nano /etc/nginx/conf.d/lab.conf`).

Save this as `/etc/nginx/conf.d/lab.conf`:

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

How the `8001` block works: `rewrite ^.*$ /special break` changes the request path to `/special` for *any* incoming path. `break` stops any further rewriting, so `proxy_pass` sends exactly `/special` to the backend. Because this `proxy_pass` has no path of its own after the port, it forwards the rewritten path as it is. NGINX never sends the client a `3xx` redirect.

The `8000` block names both backends in an `upstream` group and proxies to it. NGINX takes turns between them by default (round-robin).

---

## Step 3: Test and reload

Apply it. First test the whole configuration:

```bash
sudo nginx -t
```

If it says `syntax is ok` and `test is successful`, reload:

```bash
sudo systemctl reload nginx
```

**Run the check.** `nginx-syntax` now passes.

---

## Step 4: Check the two ports

Then check the result:

```bash
curl http://127.0.0.1:8001/
curl http://127.0.0.1:8001/anything-else
for i in $(seq 1 6); do curl -s http://127.0.0.1:8000/; echo; done
```

Port `8001` returns `app-2222-special` for both paths. Port `8000` alternates between `app-1111-root` and `app-2222-root`.

**Run the check.** `proxy-8001` and `loadbalancer-8000` now pass. All four checks are green.

---

## Step 5: Submit

```bash
astrona submit --git git@github.com:astrona-io/ATS003.git -c sections/section-050/module-01/labs/lab-01
```

---

## If a check stays red

- **`proxy-8001` fails: `/anything-else` did not return `app-2222-special`.** You used `proxy_pass http://127.0.0.1:2222/special;` (with a path), which adds the rest of the request path. Use the `rewrite ^.*$ /special break;` plus `proxy_pass http://127.0.0.1:2222;` form shown above.
- **`proxy-8001` fails: "returned HTTP 301".** You used `return 301`, or `rewrite … redirect` or `permanent`. Use `break`, not a redirect.
- **`loadbalancer-8000` fails: only one backend seen.** Both `server` lines must be inside one `upstream` block, and `proxy_pass` must point at that upstream name.
- **`nginx-syntax` fails.** Usually a missing `;` or a `{ }` pair that does not match. `sudo nginx -t` prints the file and the line.
- **`existing-apps-untouched` fails.** You edited the `1111` or `2222` file. Undo that change. All your rules belong in the new `lab.conf` only.
