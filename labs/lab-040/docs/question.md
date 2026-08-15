# Question

You need to perform OpenSSH server configuration changes on `astro-ats-003-lab-040`.

Users `elena` and `victor` exist on that server and can be used for testing. Passwords are their username and shouldn't be changed.

Please go ahead and:
- Disable X11Forwarding.
- Disable PasswordAuthentication for everyone but user `elena`.
- Enable Banner with file `/etc/ssh/sshd-banner` for users `elena` and `victor`.
