# Solution

## Step 0: Confirm existing apps are untouched and locate Nginx's include path

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:1111/
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:2222/
sudo nginx -T | grep -m1 'include'
ls /etc/nginx/conf.d/ /etc/nginx/sites-enabled/ 2>/dev/null
```

Verify both existing app ports respond before you start, so any breakage later is clearly attributable to your new config, not something already broken. `nginx -T` prints the fully-merged config with all includes resolved — look for the `include conf.d/*.conf;` (or `sites-enabled/*`) line in `nginx.conf`, since that's the directory your new file needs to land in to actually get loaded.

## Step 1: Create a new, isolated config file

```bash
sudo touch /etc/nginx/conf.d/lb-8000-8001.conf
```

A descriptive filename tells the next admin exactly what this file is for at a glance. Using `conf.d/` avoids the extra symlink step `sites-available`/`sites-enabled` requires on Debian-family systems — either works as long as it's picked up by an `include`, but a single new file is the minimal, least-invasive footprint, satisfying "don't touch the existing app configs."

## Step 2: Build the fixed-target proxy on port 8001

```nginx
# /etc/nginx/conf.d/lb-8000-8001.conf

server {
    listen 8001;
    server_name _;

    location / {
        proxy_pass http://192.168.10.60:2222/special;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Since Nginx has no offline man page for directive syntax, lean on `nginx -t`'s error messages as you iterate — write the block, test it, and let the parser tell you immediately if `proxy_pass` or a header directive is malformed, rather than trying to recall exact syntax from memory.

`listen 8001` opens a brand-new socket that has nothing to do with the app on 2222's own `server{}` block — Nginx dispatches purely by the port/host the request arrived on, so this coexists safely with the untouched app config. `proxy_pass http://192.168.10.60:2222/special;` forwards every request under `/` to that fixed backend URL, path included — this is the reverse-proxy behavior that satisfies "redirects all traffic to 192.168.10.60:2222/special" without ever exposing a 301 to the client or requiring changes to the app on 2222. The three `proxy_set_header` lines aren't strictly required by the task, but they're standard reverse-proxy hygiene: they preserve the original `Host` and client IP information for the backend app's logs, which a real API server would otherwise lose (it would just see 127.0.0.1 as the source).

## Step 3: Build the load-balanced upstream on port 8000

```nginx
# same file, appended

upstream app_pool {
    # No explicit algorithm = round robin (Nginx's default).
    # Swap the line above for `random;` to load-balance randomly instead.
    server 192.168.10.60:1111;
    server 192.168.10.60:2222;
}

server {
    listen 8000;
    server_name _;

    location / {
        proxy_pass http://app_pool;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Check `man -k nginx` and any locally installed doc package for the `upstream` module first if you're unsure of the `random;`/`least_conn;` keyword spelling — with no internet available, `nginx -t` is again the fastest way to confirm a directive name is spelled correctly, since an unrecognized directive fails syntax validation immediately with the bad token named.

`upstream app_pool { ... }` defines a named pool of backends; Nginx load-balances requests across the `server` entries inside it. With no algorithm directive, Nginx uses round-robin — each successive request goes to the next server in the list, cycling back to the top. If the task's "Random" option is preferred instead, add a `random;` line as the first statement inside the `upstream` block:

```nginx
upstream app_pool {
    random;
    server 192.168.10.60:1111;
    server 192.168.10.60:2222;
}
```

Either satisfies the task since it explicitly allows "Random or Round Robin" — round-robin (the default, shown above) requires the least code and is the safer choice under time pressure since there's nothing extra to get wrong.

## Step 4: Test syntax before touching the running service

```bash
sudo nginx -t
```

Expected:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

`nginx -t` parses and validates the *entire merged* configuration, including your new file, without affecting the running worker processes at all. Never skip this before a reload — a typo here (a missing semicolon, an unmatched brace) is the single most common way to accidentally break the untouched app configs too, since Nginx reloads its configuration as one atomic unit.

## Step 5: Reload Nginx

```bash
sudo systemctl reload nginx
```

`reload` (not `restart`) sends Nginx's master process a signal to gracefully spawn new workers with the updated config while finishing in-flight requests on the old workers — zero dropped connections for the two existing apps, which matters since you're not allowed to disrupt them.

## Verification

```bash
# Fixed-target proxy: every request on 8001 should land on the /special
# path of the 2222 app, regardless of what path the client requested.
curl -s http://192.168.10.60:8001/
curl -s http://192.168.10.60:8001/anything-else

# Load-balanced pool: repeated requests on 8000 should alternate (or
# randomize) between the 1111 and 2222 backends.
for i in $(seq 1 6); do curl -s http://192.168.10.60:8000/ | head -c 80; echo; done
```

Expected pattern for the round-robin case — alternating backend identity in the response body (assuming each app's response distinguishes itself, e.g. by port or hostname):

```text
response-from-app-on-1111
response-from-app-on-2222
response-from-app-on-1111
response-from-app-on-2222
response-from-app-on-1111
response-from-app-on-2222
```

Confirm the untouched apps still work directly:

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:1111/
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:2222/
```

Both should return the same status codes as in Step 0, proving the existing configs were never touched.

## Command Summary

```bash
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:1111/
curl -s -o /dev/null -w '%{http_code}\n' http://192.168.10.60:2222/
sudo nginx -T | grep -m1 'include'

sudo touch /etc/nginx/conf.d/lb-8000-8001.conf
sudo $EDITOR /etc/nginx/conf.d/lb-8000-8001.conf
# (add server{} on 8001 with proxy_pass to :2222/special,
#  upstream{} + server{} on 8000 balancing :1111 and :2222)

sudo nginx -t
sudo systemctl reload nginx

curl -s http://192.168.10.60:8001/
for i in $(seq 1 6); do curl -s http://192.168.10.60:8000/; echo; done
```
