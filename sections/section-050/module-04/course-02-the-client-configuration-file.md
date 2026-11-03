# The Client Configuration File

Astronaut, typing `ssh -p 2222 -i ~/.ssh/id_ed25519 pilot@localhost` ten times a day is a waste of fuel. The client configuration file, `~/.ssh/config`, lets you give each ship a short nickname and remember its address, user, port and keycard. This part shows how to write it and how to ask `ssh` what it will really do.

## A nickname for a ship

A `Host` block starts with a nickname and lists the settings for that ship. The nickname is only a label on your ship. Only `HostName` says where to connect.

### Write a first entry

Work as the visitor user (`sudo -iu cadet`).

<!-- astrona:playground:renew -->

Save this as `~/.ssh/config`:

```text
Host station
    HostName localhost
    User pilot
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Apply it. `ssh` refuses a configuration file that other users can write, so set safe permissions:

```sh
chmod 600 ~/.ssh/config
```

Then check the result. The short form should now work, using the key from the last part:

```sh
ssh station hostname
```

`IdentitiesOnly yes` tells `ssh` to offer only the named key, not every key the agent holds. This avoids the "too many authentication failures" error on ships that allow few attempts.

## What ssh really uses

Several places can set the same option: the command line, your `~/.ssh/config` and the system file `/etc/ssh/ssh_config`. The rule is simple: the **first value found wins**, in this order: command line, then your file from top to bottom, then the system file.

### Ask ssh with -G

`ssh -G` prints every setting `ssh` would use for a name, without connecting. Filter it for what you care about:

```sh
ssh -G station | grep -E '^(hostname|user|port|identityfile) '
```

The output shows the values from your `Host station` block. Because the first value wins, put specific `Host` blocks first and a general `Host *` block last.

### Watch a login with -v

When a login fails, add `-v`. It prints which configuration file `ssh` read, which keys it offered and why the server answered as it did:

```sh
ssh -v station true 2>&1 | grep -E 'Reading configuration|Offering public key|Authenticated'
```

## Jump hosts

A **jump host** is a relay ship you must pass through to reach a ship you cannot reach directly. `ProxyJump` (or `ssh -J`) makes `ssh` open the first hop and tunnel the second connection through it, so your keys never leave your own ship.

### See it in your playground

The relay ship in your playground listens on port 2223. Reach the station through it with one command:

```sh
ssh -J pilot@localhost:2223 -p 2222 pilot@localhost hostname
```

To make it permanent, add a block below `Host station` in `~/.ssh/config`. Save this as `~/.ssh/config` (the whole file, replacing the old content):

```text
Host relay
    HostName localhost
    User pilot
    Port 2223
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host station
    HostName localhost
    User pilot
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ProxyJump relay
```

Apply it. The permissions stay at `600`, but run it again after you replace a file:

```sh
chmod 600 ~/.ssh/config
```

Then check the result. For this to work, the relay needs your key too:

```sh
ssh-copy-id relay
ssh station hostname
```

## Common pitfalls

> [!WARNING]
> - **Reading the order backwards.** The first value wins, so a `Host *` block at the top overrides everything below it.
> - **Loose permissions.** `Bad owner or permissions on ~/.ssh/config` means other users can write the file. Run `chmod 600 ~/.ssh/config`.
> - **Nickname versus address.** The `Host` line is a label. If `HostName` is missing, `ssh` tries to look up the nickname as a real name.
> - **Forgetting the jump host's key.** Each hop needs its own login to work. Copy your key to the relay too.
