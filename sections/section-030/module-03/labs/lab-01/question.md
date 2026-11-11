# Route and masquerade an application request

**Learner work: 15 minutes.** Allow several minutes for three VMs to start.

The client is `172.20.10.10/24`. The router connects `172.20.10.1/24` to `172.20.20.1/24`. The server is `172.20.20.20/24`. Separate management interfaces keep SSH reachable. The client already routes `172.20.20.0/24` through the router. The server has no route back to the client subnet. Its HTTP listeners on ports 8080 and 8081 return the request's source address.

1. Inspect addresses and routes on all three VMs. On the router, enable IPv4 forwarding persistently with a file in `/etc/sysctl.d/`.
2. Configure an nftables forward chain with a drop policy. Permit established replies and new TCP connections from the inside subnet to server port 8080. Leave port 8081 blocked.
3. Masquerade inside traffic as it leaves the router's outside interface. Persist the rules in `/etc/nftables.conf` and enable the nftables service. Keep the management interfaces unchanged.
4. From the client, request `http://172.20.20.20:8080/`. The response must be `172.20.20.1`. A request to port 8081 must time out, while both listeners remain available locally on the server. Reboot only the router and repeat these checks.

Submit after completing all four tasks. The grader checks both the successful request and blocked traffic. Adding a return route on the server without masquerade does not meet the source-translation requirement.
<!-- curriculum-links -->

## Related lessons and assessment

Read [module-03](../../course.md).

The grader checks:

- Prove permitted traffic is translated and forbidden traffic is dropped.
- Check live forwarding and the boot-time firewall loader.
- Prove both destination listeners are available.

Use the inspection commands in the solution to check your work. Submit when you have finished; submission ends this environment.
