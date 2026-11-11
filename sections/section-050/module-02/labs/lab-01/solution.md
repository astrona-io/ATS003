# Solution: Balance requests across two upstreams

Run these commands as `student` inside the lab VM.

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

Use the inspection commands to verify the result before submitting. Submission ends the environment.
