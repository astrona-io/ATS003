# Routed NAT playground

The client is `172.20.10.10/24`. The router connects `172.20.10.1/24` to `172.20.20.1/24`. The server is `172.20.20.20/24`. Separate management interfaces keep SSH reachable. The client already routes `172.20.20.0/24` through the router. The server has no route back to the client subnet. Its HTTP listeners on ports 8080 and 8081 return the request's source address.


Follow the module lesson to configure the router. Renewing this playground resets all three VMs.
