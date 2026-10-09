# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module rewrote the standing orders of your ship's airlock guard, `sshd`, so that guessing passwords no longer works and every exception is deliberate.

**From [Why Harden And What Is Really In Effect](./course-01-why-harden-and-what-is-really-in-effect.md):**

- Hardening takes away passwords, limits who can log in, cuts the surface, and keeps a record. The firewall, key hygiene and jump hosts are the layers around it.
- `sshd -t` tests the configuration, `sshd -T` prints the effective configuration, and `sshd -T -C user=…,host=…,addr=…` prints it for one connection, with `Match` blocks applied.
- The file is not the truth. `sshd -T` is.

**From [Drop-Ins, Keys And Root](./course-02-drop-ins-keys-and-root.md):**

- The first value found for a keyword wins. On Ubuntu, `Include /etc/ssh/sshd_config.d/*.conf` comes first, so drop-in files beat the main file.
- `PasswordAuthentication no` and `PermitRootLogin no` are the two biggest changes. Confirm key login works before you turn passwords off.
- `PermitRootLogin prohibit-password` still lets root in with a key.

**From [Who May Log In](./course-03-who-may-log-in.md):**

- `AllowUsers` and `AllowGroups` make an allow list. Everyone else is refused before any password or key check.
- Allow lists beat deny lists, which miss accounts you did not name.
- `MaxAuthTries`, `LoginGraceTime`, `MaxStartups`, the forwarding switches and `ClientAlive*` limit what one connection can do.

**From [Match Blocks And Safe Reloads](./course-04-match-blocks-and-safe-reloads.md):**

- A `Match` block runs from its `Match` line to the next `Match` or the end of the file, so it goes at the bottom.
- A `Match` block overrides the global value for matching connections: "deny for everyone, allow for one".
- `sshd -t` catches errors before a reload. Keep a second session open when you reload a real server.

## Your missions

You proved the skills in a graded mission, right after the part that taught the last of them:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [OpenSSH Server Hardening Lab](./labs/lab-01/README.md) | Match Blocks And Safe Reloads | no X11 forwarding, password login for one user only, and a banner for both users |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. You set <code>PasswordAuthentication no</code> in <code>/etc/ssh/sshd_config</code> on Ubuntu, reload, and <code>sshd -T</code> still says <code>yes</code>. Why?</summary>

A file in `/etc/ssh/sshd_config.d/` sets it. The main file includes those files at the top, and the first value found wins. Change or comment out the drop-in setting, or put your own setting in a drop-in file.
</details>

<details>
<summary>2. How do you check the password setting that applies to the user <code>bob</code> without logging in?</summary>

`sudo sshd -T -C user=bob,host=localhost,addr=127.0.0.1 | grep '^passwordauthentication '`. The `-C` option applies the `Match` blocks for that connection.
</details>

<details>
<summary>3. Why should <code>Match</code> blocks go at the end of the file?</summary>

A `Match` block runs until the next `Match` line or the end of the file. Any global setting written after it would quietly become part of the exception.
</details>

<details>
<summary>4. Which is safer, <code>AllowGroups sshusers</code> or <code>DenyUsers bob</code>?</summary>

`AllowGroups sshusers`. An allow list refuses everyone not on it, including accounts created later. A deny list only stops the names you remembered.
</details>

<details>
<summary>5. Does <code>PermitRootLogin prohibit-password</code> stop all root logins?</summary>

No. It still allows root to log in with a key. Use `PermitRootLogin no` to stop root logins over SSH completely.
</details>

<details>
<summary>6. What do you run before every reload of <code>sshd</code>?</summary>

`sudo sshd -t` (with `-f` for another file). It reports errors without touching the running service. On a real server, also keep a second session open.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ssh-hardening-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-053
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with `astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-050/module-03/playground`. It always starts clean, so nothing you broke carries over.
