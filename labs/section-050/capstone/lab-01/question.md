# Question

Solve this question on: `web-srv1`

Server `web-srv1` is hosting two applications, one accessible on port `1111` and one on `2222`. These are served using Nginx and it's not allowed to change their config. The IP of `web-srv1` is `192.168.10.60`. Create a new HTTP LoadBalancer on that server which: Listens on port `8001` and redirects all traffic to `192.168.10.60:2222/special`. Listens on port `8000` and balances traffic between `192.168.10.60:1111` and `192.168.10.60:2222` in a Random or Round Robin fashion. Nginx is already preinstalled and is recommended to be used for the implementation.
