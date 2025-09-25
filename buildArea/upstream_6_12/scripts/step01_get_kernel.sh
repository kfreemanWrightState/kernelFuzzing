#!/usr/bin/env bash
set -euxo pipefail
# Shallow clone: only the 6.12 branch tip (not the entire repo history).
[ -d linux-6.12 ] || git clone --depth 1 --branch linux-6.12.y \
  https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git linux-6.12

