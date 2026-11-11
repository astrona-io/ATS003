# Section 010: Core Host Configuration (Addressing & Hostnames)

Make every host uniquely identifiable at Layer 3: assign static and secondary IPv4/IPv6 addresses, manage the systemd hostname, and resolve names locally with /etc/hosts.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [Network Interfaces and IPv4 & IPv6 Addressing](module-01/course.md)
2. [Managing Linux Hostnames](module-02/course.md)
3. [Discovering Your Public IP Address](module-03/course.md)
4. [Local Hostname Resolution](module-04/course.md)
5. [Dynamic Addressing with DHCP](module-05/course.md)

## Required exercises

- [IPv4 and IPv6 addressing](module-01/labs/lab-01/question.md): Add secondary IPv4 and IPv6 addresses without changing management DHCP; Persist the addresses in network configuration; Verify both addresses after a reboot.
- [Static Hostname Management Lab](module-02/labs/lab-01/question.md): Set the static and live hostname without a reboot; Set a free-form pretty hostname; Point the 127.0.1.1 line in /etc/hosts at the new name.
- [Public IP Discovery Behind NAT Lab](module-03/labs/lab-01/question.md): Find the private address on the host's own interface; Find the public address the internet sees after NAT; Write each address to a file in the exact format a script expects.
- [Repair local hostname resolution](module-04/labs/lab-01/question.md): Find the incorrect app-srv1 mapping in /etc/hosts; Repair forward and reverse NSS lookup results; Keep unrelated host mappings intact.
- [DHCP Client Lab](module-05/labs/lab-01/question.md): Turn on a DHCP client for an interface in Netplan; Keep the address from a lease and refuse its routes and DNS servers; Prove the lease with ip, networkctl and resolvectl.
- [Addressing and local resolution integration](capstone/labs/lab-01/question.md): Add a secondary IPv4 and a static IPv6 address beside the management address; Make both addresses survive a reboot in Netplan or NetworkManager configuration; Map the host name app-srv1 to its new address in /etc/hosts, forward and reverse.

Finish the [section knowledge check](quiz.yaml).

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
