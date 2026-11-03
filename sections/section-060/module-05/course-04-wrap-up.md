# Summary

Well flown, astronaut. You have finished every part of this module. Before you move on, look back at what you learned, check yourself, and land the playground cleanly.

## What you learned

This module was about a method: climb the ladder from the antenna up to the shields, and stop at the first broken rung.

**From [Work Up The Ladder](./course-01-work-up-the-ladder.md):**

- The rungs are link, address, route, name, port and firewall. The commands are `ip -br link`, `ip -br addr`, `ip route get`, `getent hosts`, `ss` with `curl -v`, and `nft list ruleset`.
- The error message names the rung: "Name or service not known" is a name fault, "Network is unreachable" and "No route to host" are lane faults, "Connection refused" is a port fault and a timeout points at the firewall.

**From [Follow The Path](./course-02-follow-the-path.md):**

- `ping` says whether anyone answers, `traceroute` and `tracepath` list the hops, and `mtr -rwn -c 5` shows loss and delay per hop.
- `* * *` and loss at a middle hop are often rate limits. Real loss continues to the last hop.

**From [Prove The Port And Read The Wire](./course-03-prove-the-port-and-read-the-wire.md):**

- `ss -tlnp 'sport = :<port>'` proves a listener, and `curl -v` shows where a request stops.
- On the wire, a closed port sends a reset back, and a dropped signal sends nothing.
- `ip -s link` shows error and drop counters.

## Your missions

| Mission | After the part | What you proved |
| --- | --- | --- |
| [Network Troubleshooting Lab](./labs/lab-01/README.md) | Prove The Port And Read The Wire | find a down link, a wrong name entry and a firewall rule, fix them, and prove the portal answers |

If you skipped it, go back to it now. It is the exam's favourite kind of task.

## Check yourself

Try to answer each question before you open the answer.

<details>
<summary>1. Which rung comes right before the firewall on the ladder?</summary>

The port. The full order is link, address, route, name, port, firewall.
</details>

<details>
<summary>2. <code>curl</code> says "Connection refused". Which rung is broken?</summary>

The port rung. The ship answered with a reset, so nothing listens on that port, or it listens on another address.
</details>

<details>
<summary>3. <code>mtr</code> shows 50% loss at hop 3 and 0% loss at the last hop. Is the lane broken?</summary>

No. Hop 3 rate-limits its own replies. Real loss would show at the last hop too.
</details>

<details>
<summary>4. Which command shows the route a signal to <code>10.66.0.10</code> would take?</summary>

`ip route get 10.66.0.10`.
</details>

<!-- astrona:playground:destroy -->
