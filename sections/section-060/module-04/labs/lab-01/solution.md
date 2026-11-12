# Solution: Capture and decode an HTTP conversation

Run these commands as `student` inside the lab VM.

Capture the healthy service traffic with a port filter and full packet contents. The timeout stops the example after eight seconds; exit 124 means that time limit was reached. `-Z root` keeps the short capture able to write the file in the student-owned directory. Changing ownership afterwards lets the student decode the saved file.

```bash
sudo timeout --signal=INT 8 tcpdump -Z root -i lo -nn -s 0 -U -w /opt/course/http.pcap 'tcp port 8080' || test "$?" -eq 124
sudo chown student:student /opt/course/http.pcap
tcpdump -nn -A -r /opt/course/http.pcap > /opt/course/decoded.txt
python3 - <<'DECODE'
from pathlib import Path
import re
text = Path('/opt/course/decoded.txt').read_text(errors='replace')
request = re.search(r'GET ([^ ]+) HTTP/1[.]', text)
assert request, 'No HTTP request captured'
Path('/opt/course/request-path').write_text(request[1] + chr(10))
token = re.search(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}', text)
assert token, 'No response token captured'
Path('/opt/course/response-token').write_text(token[0] + chr(10))
DECODE
```

Read the decoded capture before submitting the two evidence files. Find the TCP SYN and SYN-ACK, the GET URI, the successful response and its token. The extraction above searches within the decoded payload because packet headers may precede HTTP text on the same output line. The grader reads the pcap itself, so two text answers without a valid capture do not pass.

Submit when the checks pass. Submission ends the environment.
