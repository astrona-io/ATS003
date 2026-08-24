#!/usr/bin/env bash
# Bootstrap init: sets a generic pre-rename static hostname, as if this
# host was freshly provisioned from a base image and never customized.

set -eu

sudo hostnamectl set-hostname ubuntu-2404-base
