# Solution: Balance requests across two upstreams

Run these commands as `student` inside the lab VM.

The upstream block names the two existing backend servers. The server on port 8000 sends requests to that upstream. With the default round-robin selection, repeated requests should reach both applications.

```bash
sudo tee /etc/nginx/conf.d/lab.conf >/dev/null <<'CONFIG'
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
CONFIG
sudo nginx -t
sudo systemctl reload nginx
for i in $(seq 1 10); do curl -fsS http://127.0.0.1:8000/; echo; done
```

Look for both `app-1111-root` and `app-2222-root` in the responses. A single request proves only that one backend can answer. Keep the existing backend configuration and files unchanged.

Submit when the checks pass. Submission ends the environment.
