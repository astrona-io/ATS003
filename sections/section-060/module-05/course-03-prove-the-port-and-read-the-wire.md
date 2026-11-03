# Prove The Port And Read The Wire

Astronaut, the top rungs of the ladder are the port and the firewall. You prove the port with `ss` and `curl`, and when the answer still does not make sense, you clip a recorder to the antenna with `tcpdump` and look at the real signals.

## The port: listening and answering

A port can fail in two different ways. Nothing may be listening, or something listens but the signal never reaches it. `ss` answers the first question and `curl -v` answers the second.

### See it in your playground

<!-- astrona:playground:renew -->

First, who listens on the portal's channel?

```sh
sudo ss -tlnp 'sport = :8443'
```

You should see one `LISTEN` line on `0.0.0.0:8443`, owned by `python3`. Now watch a whole request step by step:

```sh
curl -v http://portal.lab:8443/
```

`curl -v` prints which address it connected to, then the request and the response headers. The line that starts with `* Connected to` tells you the name resolved and the connection opened.

A refused connection looks different. Stop the service, try again, and start it again:

```sh
sudo systemctl stop portal
curl -s -o /dev/null -w '%{http_code}\n' http://portal.lab:8443/
sudo systemctl start portal
```

`curl` fails at once with `Connection refused`. The ship answered, but nothing was listening. Compare that with the timeout from the firewall.

## The wire: tcpdump

`tcpdump` records the signals on an antenna. A timeout and a refusal look the same to a person, but they look very different on the wire.

### Compare a timeout with a refusal

Break the firewall. Then open a second shell with `astrona ssh network-troubleshooting-playground` and start the recorder there:

```sh
sudo break-firewall
```

```sh
sudo timeout 10 tcpdump -ni any 'tcp port 8443'
```

While it runs, send one request from the first shell:

```sh
curl -m 3 -s -o /dev/null http://10.66.0.10:8443/
```

You see the first `SYN` packet leave, again and again, and no reply. When a port is closed instead, you see an `RST` (reset) come straight back. When the shields drop the signal, silence comes back. Fix it before moving on:

```sh
sudo fix-all
```

## Read the counters

The interface keeps its own error count. If `ip -s link` shows `errors` or `dropped` rising while you test, the fault is on the antenna or its driver, not in the application:

```sh
ip -s link show lab0
```

## Common pitfalls

> [!WARNING]
> - **Testing the wrong address.** `curl http://127.0.0.1:8443/` can work while `http://10.66.0.10:8443/` fails. Test the address the client really uses.
> - **Stopping at "it is listening".** A listener does not mean the shields let the signal in. Test from the client side too.
> - **Capturing on the wrong antenna.** Use `-i any` if you are not sure which interface carries the traffic.
> - **Forgetting `-n` with `tcpdump`.** Name lookups slow it down and hide the real addresses.

## Your mission: Network Troubleshooting Lab

You can now climb the ladder and name the rung that breaks. The graded mission gives you a portal that clients cannot reach. At least three rungs are broken, and you must find and fix each one, in order, until `curl` gets a real answer.

The mission runs on its own training ship, so first pause your playground. Nothing in it is lost:

```sh
astrona stop network-troubleshooting-playground
```

Then start the mission:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS003.git -c sections/section-060/module-05/labs/lab-01
```

Read the task in [`question.md`](./labs/lab-01/question.md) and solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-060/module-05/labs/lab-01
```

When the mission is done, remove it and wake your playground up again:

```sh
astrona destroy ats-003-lab-065
astrona start network-troubleshooting-playground
```
