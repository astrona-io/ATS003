# Question

Solve this question on: `terminal`

## Scenario

This is the section capstone: one reverse proxy and load balancer task, with no step-by-step guidance.

Astronaut, this training ship already runs NGINX, and two apps owned by another team are live on it. They **must not be changed**:

- port `1111` serves `app-1111-root` at `/`
- port `2222` serves `app-2222-root` at `/`, and `app-2222-special` at `/special`

Their configuration files are `/etc/nginx/conf.d/app-1111.conf` and `/etc/nginx/conf.d/app-2222.conf`. Leave both files alone. Put all your work in a new NGINX configuration file of your own, and use it to open two new front-end ports.

## Tasks

1. **A fixed-target proxy on port `8001`.** Every request to port `8001`, on any path, must be reverse-proxied to the `/special` page of the app on port `2222`. It must return that page's body (starting with `app-2222-special`) with HTTP status `200`. This must be a real proxy, not a `3xx` redirect. Both `curl http://127.0.0.1:8001/` and `curl http://127.0.0.1:8001/anything-else` must return `app-2222-special`.

2. **A load balancer on port `8000`.** Requests to port `8000` must be spread over **both** backends, `127.0.0.1:1111` and `127.0.0.1:2222`. Over 10 requests, you must see both `app-1111-root` and `app-2222-root`.

3. **A valid configuration.** `sudo nginx -t` must pass for the whole configuration. The existing apps on `1111` and `2222`, including `/special`, must still serve their original content.

The grader sends real requests with `curl` to ports `1111`, `2222`, `8000` and `8001`, and runs `sudo nginx -t`.
