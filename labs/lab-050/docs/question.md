# Question

The data team needs `astro-ats-003-lab-050` reachable under a dedicated secondary address before they will point their pipeline configs at it. On interface eth0 (primary address 192.168.10.70/24), add a second static IPv4 address 192.168.10.71/24 and a static IPv6 address fd00:10::70/64 from the site's ULA range.

Both addresses must survive a reboot. Additionally, ensure the hostname `astro-ats-003-lab-050` resolves to 192.168.10.71 via `/etc/hosts`, and that reverse lookups of 192.168.10.71 resolve back to `astro-ats-003-lab-050`.

Confirm resolution works with `getent`.
