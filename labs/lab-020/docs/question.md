# Question

Solve this question on: `data-002`

Server `data-002` is used for big data and provides internally used APIs for various data operations. You're asked to implement network packet filters on interface `eth0` on `data-002`: Port `5000` should be closed. Redirect all traffic on port `6000` to local port `6001`. Port `6002` should only be accessible from IP `192.168.10.80` (server `data-001`). Block all outgoing traffic to IP `192.168.10.70` (server `app-srv1`).
