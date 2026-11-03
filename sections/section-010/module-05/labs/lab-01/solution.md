# Solution

## 1. Write the Netplan file

Save this as `/etc/netplan/70-dhcp0.yaml`:

```yaml
network:
  version: 2
  ethernets:
    dhcp0:
      dhcp4: true
      dhcp4-overrides:
        use-routes: false
        use-dns: false
```

Apply it:

```sh
sudo chmod 600 /etc/netplan/70-dhcp0.yaml
sudo netplan apply
```

Then check the result:

```sh
ip -br addr show dhcp0
```

## 2. Check the lease

```sh
ip -br addr show dhcp0
networkctl status dhcp0
```

The address is between `10.77.0.100` and `10.77.0.149`. If it is missing, wait a few seconds and look again.

## 3. Check the routes

```sh
ip route show default
```

No line ends with `dev dhcp0`.

## 4. Check the directory

```sh
resolvectl dns dhcp0
```

The list for `dhcp0` is empty.

## Grade it

Run `astrona submit -c sections/section-010/module-05/labs/lab-01` from your own terminal.
