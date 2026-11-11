# Solution: Capture and decode an HTTP conversation

Run these commands as `student` inside the lab VM.

```bash
sudo timeout --signal=INT 8 tcpdump -Z root -i lo -nn -s 0 -U -w /opt/course/http.pcap 'tcp port 8080' || test "$?" -eq 124
sudo chown student:student /opt/course/http.pcap
tcpdump -nn -A -r /opt/course/http.pcap > /opt/course/decoded.txt
awk '/GET \/token HTTP\// {print $2; exit}' /opt/course/decoded.txt > /opt/course/request-path
python3 - <<'DECODE'
from pathlib import Path
import re
text = Path('/opt/course/decoded.txt').read_text(errors='replace')
token = re.search(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}', text)
assert token, 'No response token captured'
Path('/opt/course/response-token').write_text(token[0] + chr(10))
DECODE
```

Use the inspection commands to verify the result before submitting. Submission ends the environment.
