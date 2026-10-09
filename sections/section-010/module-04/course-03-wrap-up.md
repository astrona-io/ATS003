# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about the ship's pocket address book (`/etc/hosts`) and the switchboard (NSS) that decides when to read it.

**From [The Pocket Address Book](./course-01-the-pocket-address-book.md):**

- An `/etc/hosts` line is `IP_ADDRESS CANONICAL_HOSTNAME [ALIAS ...]`. The canonical name and every alias resolve to the same address.
- `cat /etc/hosts` shows the file; `getent hosts <name>` shows what the system actually returns, through NSS.
- The `hosts:` line in `/etc/nsswitch.conf` sets the order of sources, read from left to right. With `files` before `dns`, `/etc/hosts` wins.

**From [Write An Entry And Test It](./course-02-write-an-entry-and-test-it.md):**

- Use a loopback address such as `127.0.1.1` for the machine's own name, an interface address for a name that stands for one connection, and DNS for names other machines must resolve.
- Leave the standard `localhost` lines alone.
- Changes to `/etc/hosts` work at once, with no restart.
- `getent` tests resolution only. `ping` also tests reachability, so its failures are harder to read.
- An `/etc/hosts` entry works only on the machine that holds the file.

## Your missions

You proved the skills of this module in a graded mission:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Local Hostname Name Resolution Lab](./labs/lab-01/README.md) | Write An Entry And Test It | add and persist new addresses, and make `app-srv1` resolve both ways through `/etc/hosts` |

If you skipped it, go back to it now. The exam asks for exactly these skills.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. In the line <code>192.168.1.50 prod-app-01 app-server</code>, which name is the canonical hostname?</summary>

`prod-app-01`, the first name after the address. `app-server` is an alias. Both resolve to `192.168.1.50`.
</details>

<details>
<summary>2. The <code>hosts:</code> line reads <code>hosts: files dns</code>. A name is in both <code>/etc/hosts</code> and DNS with different addresses. Which address wins?</summary>

The one in `/etc/hosts`. NSS checks the sources from left to right, and the first answer wins.
</details>

<details>
<summary>3. <code>ping db-primary</code> fails. Does that mean the name does not resolve?</summary>

Not necessarily. `ping` resolves the name and then tries to reach the address. If `ping` printed an address, resolution worked. Use `getent hosts db-primary` to test resolution on its own.
</details>

<details>
<summary>4. You added a line to <code>/etc/hosts</code>. Do you need to restart a service?</summary>

No. The change is live as soon as the file is saved. A cache such as `systemd-resolved` or `nscd` may hold an old answer for a short time.
</details>

<details>
<summary>5. Ten servers must all reach <code>prod-app-01</code> by name. Is <code>/etc/hosts</code> the right place?</summary>

No. An `/etc/hosts` entry works only on the machine that holds the file. Register the name in DNS instead.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy hostname-resolution-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-014
```

Then run `astrona list` again and check that neither name is listed any more.

You can start the playground again at any time with the `astrona run` command for its folder, `sections/section-010/module-04/playground`. It always starts clean, so nothing you broke carries over.
