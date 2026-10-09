# Wrap-Up: Mission Debrief

Well flown, astronaut. You have finished every part and the mission in this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about using `dig` to ask the Domain Name System (DNS) exact questions and read exact answers.

**From [Read A dig Answer](./course-01-read-a-dig-answer.md):**

- A recursive resolver (the address in `/etc/resolv.conf`) walks down to the authoritative server that holds the zone, and caches the answer for its TTL.
- `dig [@server] [name] [type] [+options]`: no type means `A`, no `@server` means the resolver from `/etc/resolv.conf`.
- `dig` ignores `/etc/hosts` and the Name Service Switch; `ping`, `curl` and `getent hosts` do not.
- `status: NOERROR` means no error, not "records found". The `aa` flag means the answer came from an authoritative server.
- `+noall +answer` keeps only the ANSWER section; `+short` keeps only the data and hides the status.

**From [Ask The Right Server The Right Question](./course-02-ask-the-right-server-the-right-question.md):**

- `dig @server` asks one named server and skips the resolver in `/etc/resolv.conf`.
- `dig -x <address>` builds the reverse `PTR` query in `in-addr.arpa`. Forward and reverse zones are separate and can disagree.
- `NXDOMAIN` means the name does not exist; `NOERROR` with `ANSWER: 0` (NODATA) means the name exists but has no record of that type. `SERVFAIL` and `REFUSED` are failures of the server.

**From [Aliases And Zone Transfers](./course-03-aliases-and-zone-transfers.md):**

- A `CNAME` points one name at another; `dig` shows the alias and the target's records in one answer.
- `AXFR` copies a whole zone. Servers should allow it only to their secondary servers.

## Your missions

You proved the skill in a graded mission, right after the part that taught it:

| Mission | After the part | What you proved |
| --- | --- | --- |
| [DNS Verification with dig Lab](./labs/lab-01/README.md) | Ask The Right Server The Right Question | point a client's resolver at an internal DNS server and check its records with `dig` |

If you skipped it, go back to it now. The mission is short, and the exam asks for exactly this skill.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. A name is in <code>/etc/hosts</code>. <code>ping</code> finds it, but <code>dig</code> does not. Is something broken?</summary>

No. `dig` asks DNS directly and never reads `/etc/hosts`. `ping` goes through the Name Service Switch, which usually checks `/etc/hosts` first.
</details>

<details>
<summary>2. <code>dig +short</code> prints nothing. Does the name exist?</summary>

You cannot tell. `+short` hides the `status:` line, so `NXDOMAIN` and "no records of this type" both print nothing. Run the query without `+short` and read `status:`.
</details>

<details>
<summary>3. <code>status: NOERROR</code> and <code>ANSWER: 0</code>. What does that mean?</summary>

The name exists, but it has no record of the type you asked for. This is called NODATA.
</details>

<details>
<summary>4. Which command asks the server at <code>192.168.10.53</code> for the <code>MX</code> record of <code>example.com</code>, and ignores <code>/etc/resolv.conf</code>?</summary>

`dig @192.168.10.53 example.com MX`. The `@server` part sends the query to that server only.
</details>

<details>
<summary>5. How do you find the name that claims the address <code>203.0.113.20</code>?</summary>

`dig -x 203.0.113.20`. It builds the query `20.113.0.203.in-addr.arpa` and asks for its `PTR` record.
</details>

<details>
<summary>6. What does the <code>aa</code> flag in a <code>dig</code> answer tell you?</summary>

That the answer came from a server authoritative for the zone, not from a cached copy in a resolver.
</details>

## Clean up the playground

Your playground is a training ship running on your machine. When you are done with this module, remove it, and any mission that is still running.

First, see what is still running:

```sh
astrona list
```

Remove the playground. The command takes its **name**, not its folder path:

```sh
astrona destroy dns-dig-playground
```

If `astrona list` also showed the mission, remove it the same way:

```sh
astrona destroy ats-003-lab-043
```

Then run `astrona list` again and check that neither name appears any more.

You can start the playground again at any time with the `astrona run` command from the module's landing page. It always starts clean, so nothing you broke carries over.
