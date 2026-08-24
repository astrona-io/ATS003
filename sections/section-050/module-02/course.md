# Chapter 2: Nginx Load Balancers

To scale web architectures, you group private backends inside an "upstream" block at the "http" context level:

```nginx
upstream my_pool {
    server 127.0.0.1:1111 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:2222 max_fails=3 fail_timeout=10s;
}
```

---

## Guided Practice Lab 2: Nginx Load Balancer

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-052
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure Upstream Groups
Open configuration:
```bash
nano /etc/nginx/sites-available/default
```
Declare upstream pool above server block:
```nginx
upstream backend_servers {
    server 127.0.0.1:1111;
    server 127.0.0.1:2222;
}
```
Modify server location to reference the pool:
```nginx
location / {
    proxy_pass http://backend_servers;
    proxy_next_upstream error timeout http_502;
}
```
Test and reload:
```bash
nginx -t
systemctl reload nginx
```
