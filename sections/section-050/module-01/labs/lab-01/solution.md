# Solution: Reverse proxy to a fixed backend path

Run these commands as `student` inside the lab VM.

```bash
sudo tee /etc/nginx/conf.d/lab.conf >/dev/null <<'CONFIG'
server {
    listen 8001;
    location / {
        rewrite ^.*$ /special break;
        proxy_pass http://127.0.0.1:2222;
    }
}
CONFIG
sudo nginx -t
sudo systemctl reload nginx
curl http://127.0.0.1:8001/hello
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
