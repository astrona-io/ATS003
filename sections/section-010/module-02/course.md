# Managing Linux Hostnames

A hostname is the name used to identify a Linux machine. It provides a human-readable identity, making the machine easier to recognize than using only its IP address.

For example, a hostname such as `prod-app-01` can indicate that the machine is the first application server in a production environment.

Hostnames are commonly used by:

- System administrators.
- Monitoring and logging systems.
- Configuration-management tools.
- Network services.
- Other machines on the network.

Setting a hostname does not automatically make the machine reachable by that name. A name-resolution mechanism, such as DNS or `/etc/hosts`, must map the hostname to an IP address.

## Hostname types

On Linux systems using `systemd`, a machine can have three types of hostnames:

1. Static hostname.
2. Transient hostname.
3. Pretty hostname.

### Static hostname

The static hostname is the persistent technical name configured by the administrator.

It is normally stored in:

```text
/etc/hostname
```

Because it is persistent, the static hostname remains configured after the machine restarts.

Example:

```text
prod-app-01
```

A static hostname should normally contain:

- Lowercase letters from `a` to `z`.
- Numbers from `0` to `9`.
- Hyphens (`-`).

Avoid spaces and special characters in a static hostname.

Good examples include:

```text
prod-app-01
database-02
worker-node-03
```

### Transient hostname

The transient hostname is the hostname currently used by the running Linux kernel.

It can be assigned dynamically during startup or received from a network service such as DHCP. Because it is a runtime value, it may change while the machine is running and might not be preserved after a restart.

When a static hostname is configured, it normally takes priority over a dynamically assigned transient hostname.

### Pretty hostname

The pretty hostname is an optional, human-readable description of the machine.

Unlike the static hostname, it can contain:

- Spaces.
- Uppercase letters.
- Special characters.
- UTF-8 characters.

Example:

```text
Marketing Server - Primary
```

The pretty hostname is intended for people. It should not be used as a DNS name or as the machine's technical network identity.

A machine can therefore have both a technical static hostname and a more descriptive pretty hostname:

```text
Static hostname: prod-app-01
Pretty hostname: Marketing Server - Primary
```

## Viewing the current hostname

Use the `hostnamectl` command to inspect hostname information on a system running `systemd`:

```bash
hostnamectl status
```

Example output:

```text
 Static hostname: prod-app-01
 Pretty hostname: Marketing Server - Primary
       Icon name: computer-vm
         Chassis: vm
      Machine ID: 0123456789abcdef0123456789abcdef
         Boot ID: abcdef0123456789abcdef0123456789
  Virtualization: kvm
Operating System: Ubuntu 24.04 LTS
          Kernel: Linux 6.8.0
    Architecture: x86-64
```

The exact output depends on the operating system and environment.

Important fields include:

- `Static hostname`: The persistent technical hostname.
- `Pretty hostname`: The optional human-readable description.
- `Chassis`: The type of machine, such as a server, desktop, or virtual machine.
- `Virtualization`: The detected virtualization technology.
- `Operating System`: The installed Linux distribution.
- `Kernel`: The currently running Linux kernel.
- `Architecture`: The machine's processor architecture.

The `hostname` command can also display the hostname currently used by the system:

```bash
hostname
```

To inspect the persistent hostname file directly, run:

```bash
cat /etc/hostname
```

## Setting a static hostname

Use `hostnamectl set-hostname` with the `--static` option to configure a persistent hostname:

```bash
sudo hostnamectl set-hostname prod-app-01 --static
```

The `--static` option makes it explicit that the persistent technical hostname should be changed.

The new hostname should be available immediately. A system restart is normally not required.

Display the configured static hostname:

```bash
hostnamectl hostname
```

You can also inspect the persistent hostname file:

```bash
cat /etc/hostname
```

Expected value:

```text
prod-app-01
```

## Setting a pretty hostname

Use the `--pretty` option to configure a human-readable description:

```bash
sudo hostnamectl set-hostname "Marketing Server - Primary" --pretty
```

Quotation marks are required because the description contains spaces.

The pretty hostname does not replace the static hostname. The machine now has two different names for different purposes:

```text
Static hostname: prod-app-01
Pretty hostname: Marketing Server - Primary
```

Display the pretty hostname:

```bash
hostnamectl hostname --pretty
```

Display all hostname information:

```bash
hostnamectl status
```

## Hostnames and name resolution

A hostname identifies the machine, but it does not automatically provide network name resolution.

For another machine to connect to `prod-app-01` by name, the name must be mapped to an IP address using a mechanism such as:

- A DNS record.
- An entry in `/etc/hosts`.
- A local name-resolution service.

For example, an `/etc/hosts` entry might look like this:

```text
192.168.1.50 prod-app-01
```

Without such a mapping, the hostname can still identify the local machine, but other systems might not be able to resolve it to an IP address.

Local and network name resolution are covered in the next chapter.