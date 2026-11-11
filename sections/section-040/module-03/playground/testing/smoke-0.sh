#!/usr/bin/env bash
set -euo pipefail
for tool in dig resolvectl; do command -v "$tool"; done
