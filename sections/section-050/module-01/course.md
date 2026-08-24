# Chapter 1: Nginx Reverse Proxy

Nginx acts as a high-performance intermediary, processing secure connections at the edge and forwarding packets transparently to private backend runtimes.

Example reverse proxy block:
```nginx
location / {
    proxy_pass http://127.0.0.1:2222/special/;
    proxy_set_header Host $host;
}
```

---

## Guided Practice Lab 1: Nginx Proxy Setup

### Step 1: Start the VM Sandbox
```bash
astrona run --git git@github.com:astrona-io/ATS003.git -c labs/lab-051
```
Gain root:
```bash
sudo -i
```

### Step 2: Configure location paths
Open Nginx configuration:
```bash
nano /etc/nginx/sites-available/default
```
Add a proxy routing path:
```nginx
location /special {
    proxy_pass http://127.0.0.1:2222/special/;
    proxy_set_header Host $host;
}
```
Verify syntax and reload:
```bash
nginx -t
systemctl reload nginx
```
