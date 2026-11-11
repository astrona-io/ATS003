# Section 040: Time & Domain Name Services (NTP & DNS)

Keep infrastructure timing and naming correct: configure chrony as an NTP client, run it in server mode across stratums, and verify DNS records and resolvers with dig.

## Lessons and practice

Work through the lessons in order. Each exercise starts independently.

1. [NTP Client Time Synchronization](module-01/course.md)
2. [NTP Server Mode and Stratums](module-02/course.md)
3. [DNS Verification with dig](module-03/course.md)
4. [DNS Client Resolution](module-04/course.md)

## Required exercises

- [NTP Client Time Synchronization Lab](module-01/labs/lab-01/question.md): Replace chrony's time sources with a fixed list of servers; Set minpoll and maxpoll on every source line; Prove the clock is synchronised with chronyc tracking.
- [NTP Server Mode and Stratums Lab](module-02/labs/lab-01/question.md): Turn on chrony server mode for one subnet with allow; Point a client at the internal server and remove public sources; Prove the client selected the server one stratum below it.
- [DNS Verification with dig Lab](module-03/labs/lab-01/question.md): Point the system resolver at an internal DNS server; Check A, NS, MX and reverse records with dig, with and without @server.
- [DNS Client Resolution Lab](module-04/labs/lab-01/question.md): Teach systemd-resolved a DNS server and a search domain with a drop-in; Resolve a short name through a search domain; Override one name in /etc/hosts while DNS keeps its own answer.

Finish the [section knowledge check](quiz.yaml).

See [optional and legacy exercises](../../docs/practice-variants.md) for retained older lab IDs.
