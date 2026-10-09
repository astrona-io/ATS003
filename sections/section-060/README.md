# Section 060: Persistent Configurations & Diagnostics

Astronaut, a network change made with `ip` is chalked on the console: the next restart wipes it. This section teaches you to write network settings into the ship's flight manual so they survive a reboot, and to find out what is really happening when a connection fails.

## What you will be able to do

After this section you can:

- **Keep settings with NetworkManager.** Build a static connection profile with `nmcli`, change it, activate it again, and prove it survives a reboot.
- **Keep settings with Netplan.** Write a Netplan YAML file with correct indentation, check it with `netplan get`, and apply it safely with `netplan try`.
- **Read the socket roster.** Use `ss` to see what listens on which address, which process owns a port, and which connections are open.
- **Record real traffic.** Use `tcpdump` to capture, filter and save packets, and read what a connection really sent.

## The modules

Work through the modules in order. Each one has a playground to try things in, reading parts, and a graded mission.

1. [Persistent Network Managers](./module-01/course.md): NetworkManager devices and profiles with `nmcli`.
2. [Netplan YAML Configurations](./module-02/course.md): the Ubuntu YAML front end and how to apply it without losing your session.
3. [Active Socket Diagnostics (ss)](./module-03/course.md): listening sockets, bind addresses, connections and filters.
4. [Raw Packet Capturing (tcpdump)](./module-04/course.md): capture, filter, look inside and save packets.

## Check yourself and the capstone

- [Section 060 Knowledge Check](./quiz.md): five scenario questions on this section.
- [Connection Recovery and Audit Capstone Lab](./capstone/labs/lab-01/README.md): one graded task with no step-by-step guidance. A web service is running but cannot be reached; you diagnose it with `ss` and the firewall ruleset, fix it, and prove it answers.
