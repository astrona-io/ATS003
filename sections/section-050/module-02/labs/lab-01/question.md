# Balance requests across two upstreams

Two healthy backend applications are already running. Add one NGINX frontend in `/etc/nginx/conf.d/lab.conf`.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Configure an NGINX upstream containing `127.0.0.1:1111` and `127.0.0.1:2222`, exposed on port `8000`.
2. Check the syntax, reload NGINX, and make repeated requests until you have seen both backend responses.
3. Leave both backend applications unchanged. Port `8001` is outside this exercise.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-050/module-02](../../course.md).

The grader checks:

- Confirms `nginx -t` reports the full merged configuration as syntactically valid.
- Confirms the pre-existing apps on ports 1111 and 2222 (including /special on 2222) still serve their original, unmodified content.
- Confirms port 8000 load-balances traffic across both the 1111 and 2222 backends.

Inspect your work before submitting. Submission ends this environment.
