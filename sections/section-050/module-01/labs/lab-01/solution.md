# Solution: Reverse proxy to a fixed backend path

Run these commands as `student` inside the lab VM.

The new server listens on port 8001. The rewrite replaces the request path with `/special` before NGINX proxies it to backend 2222. The `break` flag keeps processing in the current location. The backend applications remain unchanged.

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

A successful response from `/` alone is insufficient: test `/hello` as well and confirm it returns the same special page. `nginx -t` checks the full configuration before reload; the curl requests check the resulting live behavior.

Submit when the checks pass. Submission ends the environment.
