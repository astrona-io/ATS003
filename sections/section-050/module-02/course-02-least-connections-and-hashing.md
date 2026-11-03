# Least Connections And Hashing

Astronaut, round-robin treats every visitor the same. Real visitors are not the same: some take a long time in their bay, and some must come back to the same bay every time. This part shows the two other ways the docking control tower can choose a bay.

## `least_conn`: follow the load, not the count

Round-robin assumes every request costs the same. When some requests are slow and some are quick, one backend can pile up slow requests while its turn keeps coming round.

### What `least_conn` does

`least_conn;` in the `upstream` block sends each new request to the server with the **fewest active connections** right now. The tower looks at how busy each bay is, not whose turn it is.

The echo backends take `?ms=N`, so you can create slow requests whenever you want.

### New requests avoid the busy backend

Add `least_conn;` as the first line inside `upstream app_pool { … }` in `/etc/nginx/conf.d/lb.conf`. Apply it:

<!-- astrona:playground:renew -->

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Then send three slow requests in the background and six fast ones on top:

```sh
for i in $(seq 3); do curl -s "http://localhost:8080/?ms=1500" & done
sleep 0.3
for i in $(seq 6); do curl -s http://localhost:8080/ | grep '^backend'; done | sort | uniq -c
```

The fast requests avoid whichever backends still hold a slow one:

```text
      3 backend : backend-2 ...
      3 backend : backend-3 ...
```

(Shortened: the backend addresses are cut.)

With round-robin, two of the six fast requests would have waited behind a 1.5-second request on `backend-1`. `least_conn` steered around it. Remove `least_conn;` again afterwards.

## Hashing: the same key goes to the same backend

Sometimes a client, a web address or a session should keep landing on the **same** backend, for a warm cache or for state held in memory. Hashing does this: NGINX turns a key into a number and maps that number to one server.

### `ip_hash` and `hash`

- `ip_hash;` uses the client's IP address as the key. It is simple stickiness. But if clients arrive through another proxy or a CDN (content delivery network), they may all share one address and all land on one backend.
- `hash <key> [consistent];` uses any variable you name, for example `hash $request_uri consistent;`. `consistent` uses a "ketama" ring, so adding or removing a backend moves only a small part of the keys instead of all of them.

Because `curl` here always comes from `127.0.0.1`, `ip_hash` would send *every* request to one backend. `hash $request_uri` shows the spread better.

### Each path sticks to one backend

Put `hash $request_uri consistent;` as the first line of the `upstream` block, and apply it:

```sh
sudo nginx -t && sudo systemctl reload nginx
```

Then ask for three paths, three times each:

```sh
for p in /alpha /beta /gamma; do
  for i in 1 2 3; do curl -s "http://localhost:8080$p" | grep '^backend'; done
  echo ---
done
```

Each path stays on one backend, but different paths can land on different backends:

```text
backend : backend-3 ...
backend : backend-3 ...
backend : backend-3 ...
---
backend : backend-1 ...
...
```

(Shortened: only the first path is shown in full.)

Every `/alpha` went to the same backend, and `/beta` and `/gamma` to others. The split now follows the key, not the turn, so an uneven mix of keys gives an uneven load. Put the plain pool back afterwards.

## Common pitfalls

> [!WARNING]
> - **`ip_hash` behind a proxy or CDN.** Every client then shares the proxy's address, so they all hash to one backend. Use `hash` on a better key, or real sticky cookies.
> - **Expecting an even split from hashing.** Hashing spreads keys, not requests. A few busy keys can load one backend much more than the others.
> - **Forgetting `consistent`.** Without it, adding or removing one backend can move almost every key to a new backend, and every warm cache goes cold.
