# What A Reverse Proxy Does

Astronaut, before you turn NGINX into a docking control tower, you need to know what the tower actually does with a visitor's signal. This part explains the job, shows the three `nginx` commands you use all the time, and opens the configuration files on your playground.

## The tower ends one connection and opens another

A reverse proxy is not a simple relay. It reads each request, decides what to do, and then makes a new request of its own. This is what lets it do much more than pass signals along.

### Two connections, not one

NGINX **ends** the client's TCP (Transmission Control Protocol) connection. It reads the whole HTTP request. Then it opens a **separate** connection to the backend and sends a request that it writes itself.

```mermaid
flowchart LR
    C["curl (client)"] -->|"connection 1"| N["nginx :80"]
    N -->|"connection 2"| B["backend-a :9001"]
```

The client talks only to NGINX on port 80, and NGINX talks to the backend on port 9001. Because NGINX reads the full request in the middle, it can route by web address, rewrite paths and headers, balance across several backends, cache answers, and hold HTTPS at the front while the backend speaks plain HTTP.

### Forward proxy and reverse proxy

People mix these two up, so fix the difference early:

- A **forward proxy** acts for *clients*. It handles outgoing traffic, for example a company web filter that every employee's browser goes through.
- A **reverse proxy** acts for *servers*. It handles incoming traffic. NGINX in this module is a reverse proxy: the docking control tower of your ship.

## Where the tower sits

A reverse proxy is the front layer of a service. It faces the network, and the application servers sit behind it. Knowing this picture helps you decide where each setting belongs.

### The front door of the ship

The backends are often bound only to `127.0.0.1` or to a private network, so nobody can reach them directly. This pairs with the firewall (the ship's shields): open ports 80 and 443 on the proxy, and nothing on the backends. It also pairs with DNS (the galaxy-wide directory of call signs): the public name's `A` record points at the proxy, not at the app.

### Reading the letter or only the envelope

NGINX here works at **Layer 7**, the application layer. It reads the HTTP request, so it can route on path, host name and headers. A **Layer 4** load balancer (NGINX's own `stream {}` module, HAProxy in TCP mode, or a cloud load balancer) forwards raw TCP without reading it. That is faster, but it cannot route by path.

The next step once proxying works is usually TLS termination: the proxy accepts HTTPS and speaks plain HTTP to the backend. That reuses everything in this module, plus a `listen 443 ssl` block and certificates.

## The `nginx` command

Three commands cover the whole edit loop. You run them every time you change the configuration, so learn them first.

### Test, show, reload

- `nginx -t` is the **t**est. It reads the whole configuration, reports the first error, and changes nothing. Run it before every reload.
- `nginx -T` does the same check, then prints the **entire configuration NGINX ends up with**, with every `include` filled in. This is how you see what NGINX really uses.
- `sudo systemctl reload nginx` (or `nginx -s reload`) makes the running server read the configuration again, without dropping any connections.

An easy way to remember them: small `-t` is the quick check, capital `-T` is the full transcript.

### Contexts and directives

The configuration is a tree of **contexts** (`http`, then `server`, then `location`). Each context holds **directives**, one setting per line, such as `listen` or `proxy_pass`. Every directive ends with `;`.

## Where the NGINX configuration lives

NGINX reads `/etc/nginx/nginx.conf`. On Debian and Ubuntu, that file pulls in every file under `sites-enabled/` and every `*.conf` file under `conf.d/`. This section shows the shape of those files and the default server your playground starts with.

### The context tree

Inside the files, the contexts nest like this:

```text
http {
    server {              # one virtual host: listen + server_name
        location /path/ {  # a rule matched against the request URI
            ...
        }
    }
}
```

A `server` block is picked by its `listen` port and its `server_name`. A `location` block inside it is picked by matching the request path.

A file in `sites-available/` does nothing on its own. It only takes effect once it is linked into `sites-enabled/`. On your playground, `sites-available/default` is already linked.

### See the default server in your playground

Before you proxy anything, look at what NGINX serves now and which `server` block serves it.

<!-- astrona:playground:renew -->

```sh
curl -s http://localhost/ | head -n 4
sudo nginx -T | grep -nE 'listen|server_name|location|root'
```

You get the stock NGINX page and the one `server` block that serves it:

```text
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

```text
listen 80 default_server;
root /var/www/html;
location / {
```

(Shortened: the line numbers that `grep -n` adds are not shown.)

Right now `location /` serves files from `/var/www/html`. To turn this server into a proxy, you replace what a `location` does with `proxy_pass`.

## Common pitfalls

> [!WARNING]
> - **Changing the configuration without `nginx -t`.** A syntax error makes `systemctl reload` fail, and on some setups the old configuration keeps running without a word. Always test first.
> - **Editing `sites-available` and expecting a change.** The file only takes effect once it is linked into `sites-enabled/`.
> - **Mixing up forward and reverse proxies.** A forward proxy works for clients going out. A reverse proxy works for servers taking signals in.
