# Capture and decode an HTTP conversation

A healthy service on `127.0.0.1:8080` serves a fresh token for this VM. A background client makes a request every second and also generates ICMP traffic. No service or firewall repair is needed.

Estimated learner time: 10–15 minutes, plus VM startup and any reboot. This lab starts independently.

## Tasks

1. Capture loopback traffic into `/opt/course/http.pcap`, including only TCP port `8080`. Use full packet contents and keep the file under 10 MiB.
2. Stop after several complete conversations, then decode the saved capture. Identify a TCP handshake, an HTTP request and a successful response containing the body.
3. Write the captured request URI, followed by a newline, to `/opt/course/request-path`. Write the response token, followed by a newline, to `/opt/course/response-token`.
4. Check that the capture excludes ICMP traffic. Keep the fixture services running.

<!-- curriculum-links -->
## Related lessons and assessment

Read [section-060/module-04](../../course.md).

The grader checks:

- Decode a filtered pcap and verify the TCP handshake, HTTP request, response and this VM body.
- Check the request path and response token read from the capture.

Inspect your work before submitting. Submission ends this environment.
