# Question

Solve this question on: `terminal`

## Scenario

`nginx` is installed and running. Two applications are already deployed and
**must not be changed**:

- port `1111` serves `app-1111-root` at `/`
- port `2222` serves `app-2222-root` at `/`, and `app-2222-special` at
  `/special`

Add a new nginx configuration (in its own file — do not edit the existing
app configs) that puts two new front-end ports in place.

## Tasks

1. **Fixed-target proxy on port `8001`.** Every request to `8001`, on any
   path, must be reverse-proxied to the `2222` app's `/special` and return
   its body (`app-2222-special…`) with HTTP `200` — a transparent proxy,
   not a `3xx` redirect. Both `curl :8001/` and `curl :8001/anything-else`
   must come back with `app-2222-special`.

2. **Load balancer on port `8000`.** Requests to `8000` must be spread
   across **both** backends — `127.0.0.1:1111` and `127.0.0.1:2222` — so
   that over several requests you see both `app-1111-root` and
   `app-2222-root`.

3. **Config stays valid.** `sudo nginx -t` must pass for the whole merged
   configuration, and the existing apps on `1111` / `2222` (including
   `/special`) must still serve their original content.
