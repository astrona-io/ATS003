#!/usr/bin/env bash
set -euo pipefail
for tool in nginx curl; do command -v "$tool"; done
