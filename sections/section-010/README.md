# Core Host Configuration (Addressing & Hostnames)

Astronaut, before your ship can talk to anyone, it needs a call sign and a name. Every machine in your network must be clearly identifiable: it needs the right addresses on its network interfaces, a hostname that lasts, and a way to turn names into addresses.

This section teaches those basics on a live Ubuntu 24.04 machine, from the terminal, the way the exam asks for them.

## What you will be able to do

After this section you can:

- **Read and set addresses.** List the interfaces on a machine, read their state, and add IPv4 and IPv6 addresses, both for now and so they survive a reboot.
- **Manage hostnames.** Read and set the static, transient and pretty hostnames with `hostnamectl`.
- **Find your public address.** Tell a private address from a public one, and ask an outside service which address the internet sees after NAT (network address translation).
- **Resolve names locally.** Add entries to `/etc/hosts`, read the lookup order in `/etc/nsswitch.conf`, and test resolution with `getent`.

## The modules

Work through the modules in order. Each module has its own playground, a few short parts and a graded mission.

1. [Network Interfaces and IPv4 & IPv6 Addressing](./module-01/course.md): interfaces, link state, IPv4 and IPv6 addresses, prefix lengths, the default gateway, and runtime against persistent configuration.
2. [Managing Linux Hostnames](./module-02/course.md): the static, transient and pretty hostnames, and which ones survive a reboot.
3. [Discovering Your Public IP Address](./module-03/course.md): private ranges, NAT, and asking an outside service for your public egress address.
4. [Local Hostname Resolution](./module-04/course.md): `/etc/hosts`, the Name Service Switch, `getent`, and when to use DNS instead.

## Check your knowledge

When you have finished the modules, take the [section knowledge check](./quiz.md): a short multiple-choice quiz on the whole section.

## The capstone

The section ends with one graded capstone mission, with no step-by-step guidance: the [Core Host Configurations Capstone Lab](./capstone/labs/lab-01/README.md). It brings addressing, persistent configuration and local name resolution together in one task.
