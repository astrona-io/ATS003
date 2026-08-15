# Question

`terminal` sits behind NAT — either a home/office router or a cloud provider's NAT gateway, the exact topology doesn't matter for this lab. You're asked to determine and record both the machine's local, private interface address and the actual public IP address the internet sees this machine connect from, using at least two independent methods for the public address (one HTTP-based, one DNS-based), and to be able to explain in plain terms why the two numbers you found are different.

- Write the local, private (RFC1918) address into `/opt/course/private_ip`.
- Write the public, NAT-translated address into `/opt/course/public_ip`, having confirmed it via at least one HTTP-based method (`curl ifconfig.me` or `curl icanhazip.com`) and the DNS-based method (`dig +short myip.opendns.com @resolver1.opendns.com`).
