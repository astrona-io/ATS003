# Section 040: Time & Domain Name Services (NTP & DNS)

Astronaut, a fleet only works when every ship agrees on two things: what time it is, and which call sign belongs to which name. This section teaches both. You keep a ship's clock in step with the Network Time Protocol (NTP), the time signal ships use to keep their clocks in step. Then you turn a ship into a time beacon for others. Finally, you check names in the Domain Name System (DNS), the galaxy-wide directory of call signs, with the `dig` probe.

## What you will be able to do

After this section you can:

- **Keep a clock in step.** Configure chrony as an NTP client, tune how often it polls, and prove the clock is synchronised.
- **Serve time to a subnet.** Open a chrony server with `allow`, read stratum numbers, and check from the server which clients asked for the time.
- **Check DNS records.** Point a machine at a DNS server, and use `dig` to check address, mail, name server and reverse records, with and without `@server`.

## The modules

Each module has a short landing page, a few parts, a graded mission right after the part it tests, and a wrap-up. Each module also has its own playground, a training ship you can explore freely.

1. [NTP Client Time Synchronization](./module-01/course.md): chrony as a client, `server` and `pool` lines, reading `chronyc sources` and `chronyc tracking`, slewing and stepping.
2. [NTP Server Mode and Stratums](./module-02/course.md): chrony as a server, `allow` and `deny`, stratum, `local stratum`, and the firewall rule for port 123.
3. [DNS Verification with dig](./module-03/course.md): reading a `dig` answer, `@server`, reverse lookups, `NXDOMAIN` versus `NODATA`, aliases and zone transfers.

## Check your knowledge

- [Section 040 Knowledge Check](./quiz.md): multiple-choice questions on all three modules.

## The capstone

The [Time and Name Services Capstone Lab](./capstone/labs/lab-01/question.md) closes the section with one task and no step-by-step guidance: point a client at an internal DNS server and prove its records with `dig`. Start it from your own terminal:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-040/capstone/labs/lab-01
astrona submit -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-003-lab-040
```
