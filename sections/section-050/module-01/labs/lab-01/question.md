# Reverse proxy to a fixed backend path

Two healthy backend applications are already running. Add one NGINX frontend in `/etc/nginx/conf.d/lab.conf`.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Configure NGINX on port `8001` so `/`, `/hello` and any other path reach `http://127.0.0.1:2222/special`.
2. Check the syntax, reload NGINX, and test more than one request path.
3. Leave the backend applications on ports `1111` and `2222` unchanged. Port `8000` is outside this exercise.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-050/module-01](../../course.md).

The grader checks:

- Confirms `nginx -t` reports the full merged configuration as syntactically valid.
- Confirms the pre-existing apps on ports 1111 and 2222 (including /special on 2222) still serve their original, unmodified content.
- Confirms port 8001 reverse-proxies every request through to the 2222 app's /special path.

Inspect your work before submitting. Submission ends this environment.
