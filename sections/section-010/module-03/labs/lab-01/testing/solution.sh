#!/usr/bin/env bash
set -euo pipefail
ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++)if($i=="src"){print $(i+1);exit}}' > /opt/course/private_ip
curl -4 --fail --retry 3 --max-time 20 https://ifconfig.me/ip > /opt/course/public_ip
