# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about `ss`: the roster of every open radio channel on the ship and the crew member who holds it.

**From [Listening Sockets And Who Owns Them](./course-01-listening-sockets.md):**

- A socket is the kernel's endpoint for a channel: TCP (Transmission Control Protocol), UDP (User Datagram Protocol) or Unix-domain. `ss` prints the kernel's socket table and replaces `netstat`.
- `ss -tlnp` lists listening TCP sockets with numbers and owning processes; `-p` needs `sudo` for other users' sockets.
- `0.0.0.0` (or `[::]`) means every address; `127.0.0.1` (or `[::1]`) means this host only.
- A listener is not the same as reachable: the firewall must also let the traffic in.

**From [Connections, UDP And Unix Sockets](./course-02-connections-udp-unix.md):**

- `ss -tnp state established` shows live connections, one row per side.
- UDP sockets show `UNCONN`; there is no connection state.
- `ss -x` shows Unix-domain sockets, which have a file path instead of an address and never pass a firewall.
- Many `CLOSE-WAIT` sockets point to an application that does not close its connections.

**From [Filter And Find The Port Holder](./course-03-filter-and-find-the-holder.md):**

- Filters use `sport`, `dport`, `src`, `dst`, `and`, `or` and parentheses. Ports need a colon: `sport = :9000`.
- For "address already in use", `ss -tlnp 'sport = :<port>'` names the holder. Decide before you stop it.
- `ss -s` prints totals per protocol and TCP state.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Active Socket Diagnostics (ss) Lab](./labs/lab-01/README.md) | Filter And Find The Port Holder | confirm a reachable listener, remove the firewall rule that blocks it, and prove it answers |

If you skipped it, go back to it now. It is short, and the exam asks for exactly this kind of diagnosis.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. <code>ss -tlnp</code> shows a listener on <code>127.0.0.1:9000</code>. Can another machine connect to it?</summary>

No. It is bound to loopback only. Only processes on the same host can reach it, whatever the firewall allows.
</details>

<details>
<summary>2. You run <code>ss -tlnp</code> without <code>sudo</code>, and the Process column is empty. Why?</summary>

`-p` needs root to show processes that belong to other users. Run `sudo ss -tlnp`.
</details>

<details>
<summary>3. Why does <code>ss -ulnp</code> show <code>UNCONN</code> instead of <code>LISTEN</code>?</summary>

UDP is connectionless. It has no handshake and no listening state, so bound UDP sockets show `UNCONN`.
</details>

<details>
<summary>4. Which filter shows both sides of every connection on port 9000?</summary>

`'( sport = :9000 or dport = :9000 )'`, quoted, with a colon in front of each port.
</details>

<details>
<summary>5. A new server fails with "Address already in use" on port 8080. What do you do first?</summary>

Run `sudo ss -tlnp 'sport = :8080'` to see which process holds the port. Then decide whether it should own the port, is stale and can be stopped, or the new server needs another port.
</details>

## Clean up the playground

Your playground is a whole virtual machine running on your computer. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy ss-socket-diagnostics-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-063
```

Then run `astrona list` once more and check that neither name appears any longer.

You can start the playground again at any time with the `astrona run` command for this module's playground. It always starts clean, so nothing you changed carries over.
