# Section 050: Application Reverse Proxies (Nginx & SSH)

Front application runtimes safely: proxy requests with Nginx, spread load across upstream backend pools, and lock down remote access with OpenSSH server hardening.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [Nginx Reverse Proxy](module-01/course.md)
2. [Nginx Load Balancers](module-02/course.md)
3. [OpenSSH Server Hardening](module-03/course.md)
4. [OpenSSH Client: Keys, Config And Tunnels](module-04/course.md)

## Required exercises

- [Reverse proxy to a fixed backend path](module-01/labs/lab-01/question.md): Route every path on port 8001 to backend 2222 /special; Check different request paths through the proxy; Preserve the existing backend applications.
- [Balance requests across two upstreams](module-02/labs/lab-01/question.md): Build an upstream with backends 1111 and 2222; Serve both backends through port 8000; Preserve the existing backend applications.
- [OpenSSH Server Hardening Lab](module-03/labs/lab-01/question.md): Turn off X11 forwarding for every user; Allow password login for one user only with a Match block; Prove the effective configuration per user with sshd -T.
- [OpenSSH Client Lab](module-04/labs/lab-01/question.md): Create a key pair and install the public key for key login; Write a host alias in the client configuration file; Open a local port forward through an SSH server.
- [Reverse proxy and load balancing integration](capstone/labs/lab-01/question.md): Reverse-proxy every path on one port to a fixed backend path; Spread requests on another port across two backends with an upstream block; Keep the whole NGINX configuration valid and the existing apps untouched.

Finish the [section knowledge check](quiz.yaml).

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
