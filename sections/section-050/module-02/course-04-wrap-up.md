# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the docking control tower sharing visitors over several identical bays: an NGINX `upstream` pool.

**From [The Pool And Round-Robin](./course-01-the-pool-and-round-robin.md):**

- An `upstream` block in the `http` context names a pool. `proxy_pass http://app_pool;` sends requests to it.
- The default method is weighted round-robin: each server in turn. `weight=3` gives a server three shares to one.
- Backends in a pool must be interchangeable, and the load balancer itself is a single point of failure.
- NGINX here balances at Layer 7 (it reads HTTP). A Layer 4 balancer forwards raw TCP without reading it.

**From [Least Connections And Hashing](./course-02-least-connections-and-hashing.md):**

- `least_conn;` sends each request to the server with the fewest active connections, so slow requests do not pile up.
- `ip_hash;` keeps one client on one backend, but every client behind one proxy shares an address.
- `hash $request_uri consistent;` keeps one key on one backend; `consistent` moves few keys when the pool changes.

**From [Health Checks And Retries](./course-03-health-checks-and-retries.md):**

- Open source NGINX only notices failures in live traffic: after `max_fails` failures within `fail_timeout`, the server is skipped for `fail_timeout`.
- `backup` servers only get traffic when all others are unavailable; `down` takes a server out on purpose.
- `proxy_next_upstream error timeout http_502;` retries a failed request on another server. `non_idempotent` requests such as `POST` are not retried by default.

## Your missions

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Nginx Upstream Load Balancers Lab](./labs/lab-01/README.md) | The Pool And Round-Robin | a load balancer over two apps and a fixed-target proxy, with the existing apps untouched |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A pool has <code>server A weight=3;</code> and <code>server B;</code>. Out of 8 requests, about how many go to A?</summary>

About 6. A gets three shares for every one share of B, so the split is 3 : 1.
</details>

<details>
<summary>2. Some requests take seconds, others milliseconds. Which method keeps fast requests from waiting behind slow ones?</summary>

`least_conn;`. It picks the server with the fewest active connections right now, instead of the next one in turn.
</details>

<details>
<summary>3. You set <code>ip_hash;</code> and every request lands on one backend. Why?</summary>

All requests come from the same client address, for example because they pass through another proxy or a CDN first. Hash on a better key, such as `hash $request_uri consistent;`.
</details>

<details>
<summary>4. A backend is down, but NGINX still sends it some requests. Is that a bug?</summary>

No. Open source NGINX has only passive health checks. It needs `max_fails` failed live requests within `fail_timeout` before it skips the server.
</details>

<details>
<summary>5. A backend returns HTTP 500 again and again, but NGINX never marks it unhealthy. What do you add?</summary>

`http_500` to `proxy_next_upstream`. Only the conditions listed there count as failures; by default that is connection errors and timeouts.
</details>

<details>
<summary>6. Why does NGINX not retry a <code>POST</code> on another backend by default?</summary>

A retry could apply the same change twice. Only `non_idempotent` in `proxy_next_upstream` allows it, and you should only add that when the backend can handle a repeated request safely.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy nginx-lb-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-052
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-02/playground`. It always starts clean, so nothing you broke carries over.
