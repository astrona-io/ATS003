# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Plain English

Write the text in Plain English for a general adult audience (18+) without a
university degree. The content must be highly accessible and easy to
understand for non-technical readers, without feeling childish.

Strict guidelines:

1. Target a Flesch-Kincaid Grade Level of 8 or 9 (equivalent to a standard
   newspaper article).
2. Avoid all technical jargon, acronyms, and corporate buzzwords. If a
   technical term is necessary, explain it immediately using an everyday
   analogy.
3. Keep sentences conversational and direct. Split long sentences into two.
4. Use short paragraphs (max 3-4 sentences per paragraph) and clear
   subheadings to make the text scannable.
5. Use the active voice (e.g., "We did this" instead of "This was done by us").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page and a few
  deep-dive parts. The landing page is a map: goals, what to know first, the
  order of the parts, where it fits. The real teaching goes in the parts. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module, the wrap-up links and `astrona.yaml`.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `netlab-a` interface up"). The wrap-up page is the one
  exception: it recaps each part and links to it.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Keep them, but explain
  each one in plain words, with an everyday analogy, the first time it appears
  in a file. Spell out acronyms on first use, with a short plain meaning.
- **Analogies come from space, and the reader is an astronaut.** When a term
  needs an everyday picture, use space: spaceships, planets, solar systems,
  space stations, mission control, signals, docking, star charts, airlocks,
  even the Death Star. Talk to the reader as an astronaut (for example "your
  first mission", "astronaut, check your flight log"), but not in every
  sentence. Requests are **signals** that ships send to each other. Use one
  analogy per hard idea, keep it short, and keep it the same everywhere (if
  the repository has an analogy glossary, use it). The analogy helps the reader; it
  never replaces the real term, and it never changes code or output.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are normal page
  content, not boxes: a short `###` subsection (for example "See it in your
  playground") with one sentence saying what to do, the command, the real
  output, and one or two sentences saying what it shows. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`. The
  wrap-up lists the missions and ends with cleaning up the playground
  (`astrona list`, `astrona destroy <playground name>`).
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), wrap-up pages or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"bond0"`, `"chronyd"`, `"nginx"`).
  - Put the logic on the arrows: `C -->|"NTP request"| S`,
    `N -->|"proxy_pass"| A`, `P -->|"dport 22"| R`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant C as client`)
    and short message text.
  - Anything longer (full paths, full hostnames) goes in the sentence under
    the diagram.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:8080`,
  `curl https://ifconfig.me`), and the Mission Briefing's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  a configuration file (Netplan YAML, an nftables ruleset, an NGINX site,
  `chrony.conf`, `sshd_config`) in course parts, playground docs or labs,
  use three separate steps:
  1. "Save this as `/etc/netplan/60-bond0.yaml`:" followed by a plain
     block (` ```yaml `, ` ```nft `, ` ```nginx `, ` ```ini `) with only the
     file's content. No `cat > file <<'EOF'`, no `sudo tee file <<EOF`, no
     shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only the command that
     makes the system use the file (`sudo netplan apply`,
     `sudo nft -f /etc/nftables.conf`, `sudo systemctl reload nginx`).
  3. "Then check the result:" followed by the check commands, if any.
  The file name says what the file is for. If a value must come from the
  reader's machine (an IP address), use a placeholder like `<PARTNER>` in the
  file and say how to get the value (`echo $PARTNER`); never put shell
  variables inside a configuration file that does not expand them. Apply a
  file the first time its content appears; do not show it once "to read"
  and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_port`, `count_backends`,
  `$GATEWAY_IP`), never single letters.

## About this repo (ATS003 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** pass the **Networking** domain of the **Linux Foundation
  Certified System Administrator (LFCS)** exam. It is 25% of the exam.
- **What the exam really tests:** doing real network administration on a
  live Linux machine, from a terminal, under time pressure, and leaving the
  machine in the right state, often after a reboot. So the student must *do*
  things (add an address, rename a host, build a bond, add a route, write a
  firewall rule, point a client at a time server, put NGINX in front of an
  app, harden `sshd`), not just recognise words. Every explanation should
  lead to something they can run, and every result should be proved with a
  check command (`ip addr`, `ip route get`, `getent hosts`, `nft list
  ruleset`, `chronyc tracking`, `dig`, `curl`, `sshd -T`, `ss -tulpn`).
- **The exam topics this course covers:** IP addressing and hostname
  resolution; time synchronization; network monitoring and troubleshooting;
  the OpenSSH server and client; packet filtering, NAT and port redirection;
  static routing; bridge and bonding devices; reverse proxies and load
  balancers. The README lists them as the official objectives.
- **The sections:**

  | Section | Title | Exam topic |
  | --- | --- | --- |
  | 010 | Core Host Configuration (Addressing & Hostnames) | IP addressing and hostname resolution |
  | 020 | Link Aggregation & Routing (Bridges, Bonds & Routes) | Bridge and bonding devices, static routing |
  | 030 | Network Security & Packet Filtering (Firewalls) | Packet filtering, NAT and port redirection |
  | 040 | Time & Domain Name Services (NTP & DNS) | Time synchronization, hostname resolution |
  | 050 | Application Reverse Proxies (Nginx & SSH) | Reverse proxies and load balancers, OpenSSH |
  | 060 | Persistent Configurations & Diagnostics | IP addressing (persistent), monitoring and troubleshooting |

- **The version:** every playground and lab runs on **Ubuntu 24.04** in a
  `qemu` virtual machine built from
  `ghcr.io/astrona-io/ubuntu-qcow2-image:24.04-lfcs-{ARCH}`, with **systemd**,
  **Netplan** (cloud-init file for the management interface), **iproute2**,
  **nftables** as the firewall backend, **chrony**, **NGINX**, **BIND** (the
  DNS labs) and **OpenSSH**. Do not teach options or behaviour from other
  distributions (Red Hat `ifcfg` files, `iptables`-only firewalls,
  `ntpd`) without saying so.
- **The main sources:** the manual pages on the lab machine (`man ip`,
  `man ip-route`, `man netplan`, `man nmcli`, `man nft`, `man firewall-cmd`,
  `man chrony.conf`, `man dig`, `man sshd_config`, `man ss`, `man tcpdump`)
  and the official NGINX documentation. Check every page against them.

### Space analogy glossary

Use these pictures for these terms, in every course page, lab and playground.
Keep them consistent so the astronaut builds one picture of the universe. It
is the same universe as the other Astrona courses: the learner is an
astronaut, and a single Linux machine is one spaceship. Most pages written
before these rules have no space analogies yet; add them when you rework a
page, using this table.

**The ship**

| Term | Space picture |
| --- | --- |
| The learner | An astronaut (a cadet on their first missions) |
| Linux machine / virtual machine | A spaceship |
| Playground or lab virtual machine (`qemu`) | A training ship in the simulator |
| Two machines on one lab segment (`target` and `gateway`, `client` and `dns`) | Two ships flying in formation, linked by their communications arrays |
| Kernel | The ship's core: it runs everything, and it moves every signal in and out |
| Process / service (`systemd`) | A crew member / a station that must always be staffed |
| `sudo` / `root` | Borrowing the captain's authority / the captain |
| File / configuration file | A crate in the cargo hold / the written orders a station reads at start-up |

**The communications array (interfaces and addresses)**

| Term | Space picture |
| --- | --- |
| Network | The communications array and the space lanes between ships |
| Network interface (NIC) | One antenna on the communications array |
| Management interface | The antenna that carries your link to mission control (your SSH session): never touch it |
| Loopback (`lo`, `127.0.0.1`) | The ship's internal intercom: signals never leave the hull |
| `dummy` interface | A practice antenna bolted to the hull, wired to nothing |
| Link state (`UP`, `DOWN`, `LOWER_UP`) | Antenna switched on / switched off / actually picking up a carrier |
| MAC address | The serial number stamped on the antenna |
| IP address | The ship's call sign on the space lanes |
| IPv4 / IPv6 | The old short call signs / the new long ones (there are far more of them) |
| Prefix length (`/24`, `/64`) | How much of the call sign names the sector and how much names the ship |
| Subnet | A sector of space whose ships can hail each other directly |
| Private address (RFC 1918) / public address | A call sign used only inside the home fleet / the call sign the wider galaxy sees |
| NAT (network address translation) | The relay station that swaps every outgoing call sign for its own |
| DHCP | The harbour master who hands out call signs to arriving ships |
| Static address | A call sign painted on the hull by the crew |
| Persistent vs runtime configuration | Written into the flight manual (survives a restart) vs chalked on the console (gone at the next restart) |
| Netplan / NetworkManager / `systemd-networkd` | The flight manual for the communications array / two different communications officers who read it and set the antennas |

**Names**

| Term | Space picture |
| --- | --- |
| Hostname (static, transient, pretty) | The ship's registered name / the name it answers to right now / the decorated name painted for visitors |
| `/etc/hosts` | The ship's own pocket address book |
| DNS | The galaxy-wide directory of call signs |
| Resolver (`/etc/resolv.conf`, `systemd-resolved`) | The directory clerk on board who looks names up |
| `nsswitch.conf` (`hosts: files dns`) | The order the clerk checks: pocket book first, then the directory |
| Zone, record (`A`, `AAAA`, `MX`, `NS`, `PTR`) | One page of the directory / one line on it (address, mail station, directory keeper, reverse lookup) |
| `dig` | A probe that asks one directory office one exact question |

**Links, bonds and routes**

| Term | Space picture |
| --- | --- |
| Bridge (`br0`) | A docking hub: every antenna plugged into it shares one local lane |
| Bond (`bond0`), member (slave) interface | Two antennas teamed as one, so losing one does not cut the link / one antenna in the team |
| `active-backup` mode | One antenna talks, the other waits to take over |
| Routing table | The ship's star chart: which lane to take for each sector |
| Default route / gateway (next hop) | The lane for "everywhere else" / the relay ship that passes signals on |
| Static route | A lane drawn on the star chart by hand |
| `ip route get` | Asking the navigator which lane a signal to one call sign would take |
| Metric | The cost of a lane: lower wins when two lanes go to the same sector |

**Shields (firewalls)**

| Term | Space picture |
| --- | --- |
| Packet | One signal burst |
| Netfilter (in the kernel) | The ship's shield generator |
| nftables (`nft`) | The console you use to program the shields |
| Table / chain / rule | A shield program / one checkpoint in it / one line the checkpoint reads |
| Hook (`input`, `output`, `prerouting`, `forward`) | The place on the hull where the checkpoint stands |
| Verdict (`accept`, `drop`, `reject`) | Let the signal through / let it vanish / bounce it back with a refusal |
| Policy | What the checkpoint does with signals no rule matched |
| Connection tracking (`ct state`) | The shield's memory of conversations already in progress |
| Port redirect (`redirect`, DNAT) | Re-routing an incoming signal to another radio channel or another ship |
| Port | A radio channel on the antenna |
| firewalld zone | A shield preset for one group of antennas (trusted, public, and so on) |
| Runtime vs permanent (`--permanent`) | The shield setting now / the setting saved for the next start |

**Time**

| Term | Space picture |
| --- | --- |
| NTP | The time signal ships use to keep their clocks in step |
| chrony (`chronyd`, `chronyc`) | The ship's clockmaster / the console you use to talk to it |
| Time source (`server`, `pool`) | A beacon that broadcasts the time |
| Stratum | How many relays the time passed through since the master clock |
| `allow` (server mode) | Letting other ships set their clocks from yours |

**Docking ports and inspection**

| Term | Space picture |
| --- | --- |
| SSH / `sshd` | A sealed communications channel between two ships / the airlock guard who opens it |
| `sshd_config`, `Match` block | The airlock guard's standing orders / an exception for one crew member |
| Key-based login / password login | Opening the airlock with a keycard / by saying the password |
| Reverse proxy (NGINX) | The docking control tower: visitors talk to the tower, and the tower forwards them to the right bay |
| Upstream / load balancing | The bays behind the tower / sharing visitors over several bays |
| Socket / listening socket | An open radio channel / a channel waiting for a call |
| `ss` | The roster of every open channel and which crew member holds it |
| `tcpdump` / capture file (`.pcap`) | A recorder clipped onto an antenna / its tape |

### The machines and what they contain

There is no shared sample application. Every playground and graded lab boots
its own training ship (one Ubuntu 24.04 virtual machine, two where a module
needs a partner), and its `bootstrap/` script sets up a small scenario. Use
these names exactly as the scripts create them.

**Playgrounds** (one per module, ungraded; the name is `metadata.name`):

| Module | Playground name | What the bootstrap sets up |
| --- | --- | --- |
| 010-01 | `network-interfaces-playground` | Dummy interfaces `netlab-a` (`192.168.50.10/24`, `2001:db8:50::10/64`) and `netlab-b` (UP, no address) |
| 010-02 | `linux-hostnames-playground` | Static hostname `web-01`, transient `dhcp-guest-42`, pretty unset |
| 010-03 | `public-ip-playground` | An extra interface with `172.16.20.50/24` beside the management address |
| 010-04 | `hostname-resolution-playground` | Hostname `prod-app-01`; `/etc/hosts` with `127.0.1.1 prod-app-01 app-server` and `192.168.50.10 db-primary db` |
| 020-01 | `linux-bonding-playground` | Two spare member interfaces (segments `bond-net-a`, `bond-net-b`), `bonding` module loaded, no `bond0` |
| 020-02 | `linux-bridging-playground` | Two spare bridge-port interfaces on segment `bridge-net`, no `br0` |
| 020-03 | `static-routing-playground` | `10.0.0.50/24` (`route-net-a`) and `192.168.70.50/24` (`route-net-b`) |
| 030-01 | `nftables-filtering-playground` | An empty ruleset, a dummy interface with `192.168.80.10/24` |
| 030-02 | `firewalld-zones-playground` | firewalld at stock defaults (zone `public`), a dummy interface with `192.168.90.10/24` |
| 040-01 | `ntp-chrony-playground` | Two machines: `ntp-server` (`192.168.100.10`, `local stratum 8`) and `ntp-client` (`192.168.100.20`, no sources) |
| 040-02 | `ntp-server-playground` | Two machines: `ntp-server` (`192.168.101.10`, no `allow` line) and `ntp-client` (`192.168.101.20`) |
| 040-03 | `dns-dig-playground` | A local BIND server for the zone `lab.example` and its reverse zone `113.0.203.in-addr.arpa` |
| 050-01 | `nginx-proxy-playground` | NGINX on port 80, echo backends `backend-a` (`127.0.0.1:9001`) and `backend-b` (`127.0.0.1:9002`) |
| 050-02 | `nginx-lb-playground` | NGINX load balancer on port 8080 (`/etc/nginx/conf.d/lb.conf`, `upstream app_pool`), backends on `9001` to `9003` |
| 050-03 | `ssh-hardening-playground` | A second `sshd` on port 2222 (`/etc/ssh/sshd_test.conf`, `sshd-test.service`), users `alice` and `bob` |
| 060-01 | `networkmanager-nmcli-playground` | NetworkManager managing only one spare interface on `192.168.120.0/24` |
| 060-02 | `netplan-yaml-playground` | One spare interface on `192.168.130.0/24` with no Netplan file (name in `/root/lab-spare-iface`) |
| 060-03 | `ss-socket-diagnostics-playground` | Listeners `lab-http-any` (`0.0.0.0:8080`), `lab-http-local` (`127.0.0.1:9000`), `lab-http-v6`, `lab-udp`, `lab-unix`, `lab-estab` |
| 060-04 | `tcpdump-capture-playground` | `lab-traffic.service` on `lo`, `lab-http.service`, sample capture `/usr/local/share/lab-sample.pcap` |

**Graded labs** (one per module plus one capstone per section):

| Lab name | Folder | What the task is |
| --- | --- | --- |
| `ats-003-lab-011` | `section-010/module-01/labs/lab-01` | Add `192.168.10.71/24` and `fd00:10::70/64` to the primary interface, persist them, map `app-srv1` in `/etc/hosts` |
| `ats-003-lab-012` | `section-010/module-02/labs/lab-01` | Rename `ubuntu-2404-base` to `web-srv1`, pretty name `Web Server 1 (Frankfurt)`, fix the `127.0.1.1` line |
| `ats-003-lab-013` | `section-010/module-03/labs/lab-01` | Write the private and public address to `/opt/course/private_ip` and `/opt/course/public_ip` |
| `ats-003-lab-014` | `section-010/module-04/labs/lab-01` | Same task and graders as `ats-003-lab-011` |
| `ats-003-lab-010` | `section-010/capstone/labs/lab-01` | Same graders as `ats-003-lab-011`, with no guidance |
| `ats-003-lab-021` | `section-020/module-01/labs/lab-01` | Bridge `br0` over `dummy0`, `active-backup` bond `bond0` over `dummy1` and `dummy2`, persisted |
| `ats-003-lab-022` | `section-020/module-02/labs/lab-01` | Same task and graders as `ats-003-lab-021` |
| `ats-003-lab-023` | `section-020/module-03/labs/lab-01` | Two machines: route `10.10.30.0/24` via `10.10.20.1` on `target`, persisted |
| `ats-003-lab-020` | `section-020/capstone/labs/lab-01` | Same graders as `ats-003-lab-023`, with no guidance |
| `ats-003-lab-031` | `section-030/module-01/labs/lab-01` | nftables: drop port 5000, redirect 6000 to 6001, allow 6002 only from `192.168.10.80`, block egress to `192.168.10.70` |
| `ats-003-lab-032` | `section-030/module-02/labs/lab-01` | firewalld: allow `https` and `8443/tcp` in zone `public`, runtime and permanent |
| `ats-003-lab-030` | `section-030/capstone/labs/lab-01` | Same graders as `ats-003-lab-031`, with no guidance |
| `ats-003-lab-041` | `section-040/module-01/labs/lab-01` | chrony client: four `server` lines with `minpoll 4 maxpoll 10`, synchronised |
| `ats-003-lab-042` | `section-040/module-02/labs/lab-01` | Two machines: chrony server with `allow 192.168.10.0/24`, client using `astrona-ats-003-lab-042-server` |
| `ats-003-lab-043` | `section-040/module-03/labs/lab-01` | Two machines: point `client` at the `dns` machine, check records of `internal.example.com` with `dig` |
| `ats-003-lab-040` | `section-040/capstone/labs/lab-01` | Same task as `ats-003-lab-043`, with no guidance |
| `ats-003-lab-051` | `section-050/module-01/labs/lab-01` | NGINX: port `8001` proxies to `2222/special`, port `8000` balances `1111` and `2222` |
| `ats-003-lab-052` | `section-050/module-02/labs/lab-01` | Same task and graders as `ats-003-lab-051` |
| `ats-003-lab-053` | `section-050/module-03/labs/lab-01` | `sshd`: no X11 forwarding, password login only for `elena` (not `victor`), banner `/etc/ssh/sshd-banner` |
| `ats-003-lab-050` | `section-050/capstone/labs/lab-01` | Same graders as `ats-003-lab-051`, with no guidance |
| `ats-003-lab-061` | `section-060/module-01/labs/lab-01` | Same task and graders as `ats-003-lab-013` (private and public address) |
| `ats-003-lab-062` | `section-060/module-02/labs/lab-01` | Same task and graders as `ats-003-lab-013` (private and public address) |
| `ats-003-lab-063` | `section-060/module-03/labs/lab-01` | `myapp` on port 8080 is blocked by an nftables `drop` rule: find it with `ss`, remove it, prove it with `curl` |
| `ats-003-lab-064` | `section-060/module-04/labs/lab-01` | Same task and graders as `ats-003-lab-063` |
| `ats-003-lab-060` | `section-060/capstone/labs/lab-01` | Same graders as `ats-003-lab-063`, with no guidance |

Several module labs share a task with another module's lab (see the table).
The labs in modules 060-01 and 060-02 do not test NetworkManager or Netplan
yet; their task is the address audit. Do not describe them as something
else: a lab's docs must match its `validation/` scripts.

### Environment facts the text must respect

- **Every machine is a `qemu` virtual machine, not a container.** Labs use 2
  CPUs, 2048 MB of memory and a 15 GB disk; playgrounds use a 20 GB disk.
  The learner reaches a machine with `astrona ssh <name>`. There is no
  `kubectl`.
- **Never touch the management interface.** It carries the learner's SSH
  session, its DHCP address and the default route, and its Netplan file is
  written by cloud-init. Bridging, bonding, re-addressing or firewalling it
  cuts the learner off. Labs and playgrounds give spare or `dummy`
  interfaces for that work.
- **Lab segments are point-to-point.** The `qemu` backend links exactly two
  machines per segment (`backend-net` `10.10.20.0/24`, `ntp-net`,
  `bond-net-a` and so on). A one-machine playground uses `dummy` interfaces
  instead, so nothing beyond the machine answers a `ping` from them.
- **Packages ship in the base image.** `iproute2`, `nftables`, `firewalld`,
  `chrony`, `nginx`, `openssh-server`, `curl`, `dnsutils`, `tcpdump` and
  `sshpass` are already installed. Do not tell the reader to install them.
- **Outbound internet** is available in the public address lab
  (`ats-003-lab-013`, `curl ifconfig.me`, `dig myip.opendns.com`) and the
  chrony client lab (`pool.ntp.org`). The NTP and DNS playgrounds are
  isolated on purpose: no internet NTP or DNS there.
- **Grading runs from the learner's own terminal** with `astrona submit`, not
  inside the virtual machine.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections table, how to run things | `README.md` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, wrap-up | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Section knowledge check (multiple choice) | `sections/section-0N0/quiz.md` |
| Final domain quiz | `sections/final-domain-quiz.md` |
| Graded lab: task, walkthrough, setup, grader | `.../module-0M/labs/lab-01/` (`question.md`, `solution.md`, `bootstrap/`, `validation/`) |
| Ungraded sandbox for a module | `.../module-0M/playground/` (`config.yaml`, `bootstrap/prepare.sh`, `docs/overview.md`) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` has `question: "question.md"` and `solution: "solution.md"` |
| `README.md` | Short intro with the run command |
| `question.md` | The exam-style task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough with real output |
| `bootstrap/` | Starting state of the machine, never the graded result |
| `validation/` | Grading scripts that check the machine's real state |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has one entry per section under `modules:` (`module-010` to
`module-060`, plus `module-090` for the final quiz). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-01/question.md`) followed by the `type: lab` entry; the
module's wrap-up page comes last. The section quiz and then the section
capstone close the section. Playgrounds are not listed: the landing page's
`<!-- astrona:playground -->` marker shows them.

Every `type: lab` entry (module labs and capstones) carries these fields, in
this order:

```yaml
      - type: reading
        title: Question
        path: sections/section-020/module-03/labs/lab-01/question.md
      - type: lab
        title: "Multi-Interface Static Routing Lab"
        path: sections/section-020/module-03/labs/lab-01
        difficulty: intermediate
        estimated_duration: 20m
        topic: routing
        task_kind: build
        tags: [ip-route, static-route, next-hop, route-get, netplan, persistence]
        learning_goals:
          - Add a static route to a partner subnet through a gateway
          - Prove the route with ip route get and a real ping
          - Make the route survive a reboot in on-disk configuration
        resources:
          - name: "ip-route(8) manual page"
            url: https://man7.org/linux/man-pages/man8/ip-route.8.html
```

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`, `45m`.
- `topic`: exactly one of `addressing`, `hostnames`, `name-resolution`,
  `bonding-bridging`, `routing`, `packet-filtering`, `firewalld`,
  `time-sync`, `dns`, `reverse-proxy`, `load-balancing`, `ssh`,
  `persistent-config`, `troubleshooting`.
- `task_kind`: exactly one of `build` (create the result from scratch),
  `troubleshooting` (find and fix what is broken) or `migration` (move a
  working setup to another form or place, for example runtime settings to
  persistent configuration). The platform filters labs by it, so it is a
  field of its own, never a tag.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb, saying
  what the learner proves in this lab.
- `resources`: 1 to 4 documentation pages, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed: the
  platform shows them as optional further reading next to the lab.

**Tag list** (lower case, hyphens, never synonyms):

- Addressing: `ip-addr`, `ipv4`, `ipv6`, `secondary-address`,
  `prefix-length`, `private-address`, `public-address`, `nat`
- Names: `hostnamectl`, `etc-hostname`, `etc-hosts`, `getent`,
  `nsswitch`, `resolv-conf`, `dig`, `dns-records`, `reverse-dns`
- Links and routes: `ip-link`, `bridge`, `bond`, `active-backup`,
  `dummy-interface`, `ip-route`, `static-route`, `next-hop`, `route-get`
- Persistence: `netplan`, `nmcli`, `networkmanager`, `systemd-networkd`,
  `persistence`
- Firewalls: `nftables`, `nft-tables`, `nft-chains`, `port-redirect`,
  `source-filter`, `egress-filter`, `firewalld`, `firewalld-zones`,
  `runtime-permanent`
- Time: `chrony`, `ntp-client`, `ntp-server`, `poll-interval`, `stratum`
- Proxies and SSH: `nginx`, `reverse-proxy`, `proxy-pass`, `upstream`,
  `load-balancing`, `sshd-config`, `match-block`, `password-auth`,
  `x11-forwarding`, `ssh-banner`
- Diagnostics: `ss`, `listening-sockets`, `tcpdump`, `curl`, `ping`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-03/playground
astrona ssh static-routing-playground         # open a terminal on the machine
astrona stop static-routing-playground        # pause it while a lab runs
astrona start static-routing-playground
astrona destroy static-routing-playground     # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live virtual machine)
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-020/module-03/labs/lab-01
astrona ssh ats-003-lab-023
astrona submit -c sections/section-020/module-03/labs/lab-01
astrona destroy ats-003-lab-023

# Authors: run a local, uncommitted copy and check its configuration
astrona run -c sections/section-020/module-03/labs/lab-01
astrona validate -c sections/section-020/module-03/labs/lab-01
```

Names: a playground is named in its `config.yaml` (see the playground table
above). Labs are `ats-003-lab-<section><module>`, for example
`ats-003-lab-023`, and section capstones `ats-003-lab-<section>0`, for
example `ats-003-lab-020`. A new lab takes `ats-003-lab-<section><module>-<lab>`,
so two labs never share a name.

Graders check **the machine's real state** (addresses with the right scope,
routes the kernel actually selects, the live ruleset, a synchronised clock,
real answers from `dig` and `curl`, the effective `sshd -T` configuration,
on-disk configuration for persistence), not what the learner typed. A lab's
`question.md` and `solution.md` must match what its `validation/` scripts
actually check.

Test machines on the maintainer's computer: one at a time. Podman has 10 GiB
and also runs the platform stack; parallel labs run it out of memory.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **iproute2:** the `ip` manual pages, <https://man7.org/linux/man-pages/man8/ip.8.html>,
  `ip-address(8)`, `ip-link(8)`, `ip-route(8)`, `bridge(8)`, `ss(8)`.
- **Bonding and bridging:** the kernel bonding guide,
  <https://www.kernel.org/doc/html/latest/networking/bonding.html>.
- **Persistent configuration:** Netplan, <https://netplan.readthedocs.io/>;
  NetworkManager `nmcli`,
  <https://networkmanager.dev/docs/api/latest/nmcli.html>; systemd
  (`hostnamectl`, `systemd-networkd`, `systemd-resolved`),
  <https://www.freedesktop.org/software/systemd/man/latest/>.
- **Firewalls:** the nftables wiki, <https://wiki.nftables.org/>, and
  firewalld, <https://firewalld.org/documentation/>.
- **Time:** chrony, <https://chrony-project.org/documentation.html>.
- **DNS:** `dig(1)` and BIND 9, <https://bind9.readthedocs.io/>.
- **Proxies:** NGINX, <https://nginx.org/en/docs/> (`ngx_http_proxy_module`,
  `ngx_http_upstream_module`).
- **SSH:** OpenSSH manual pages, <https://www.openssh.com/manual.html>
  (`sshd_config(5)`, `sshd(8)`).
- **Capture:** <https://www.tcpdump.org/manpages/tcpdump.1.html>.
- **Ubuntu specifics:** <https://manpages.ubuntu.com/> for the 24.04 (noble)
  man pages the labs run.
- **The exam itself:** the LFCS page on the Linux Foundation training site
  lists the official curriculum. The domain weight (25%) and the exam topic
  names above come from this repository's README and `astrona.yaml` and have
  not been re-checked against it.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository: planning
(`domain-plan`), creating the tree (`domain-scaffold`), building modules
(`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds (`lab`),
lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
