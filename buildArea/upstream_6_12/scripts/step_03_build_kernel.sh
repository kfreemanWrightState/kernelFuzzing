#!/usr/bin/env bash
set -euxo pipefail
cd linux-v6.12

#export ARCH=arm64
#export CROSS_COMPILE=aarch64-linux-gnu-

# Build the Image (arm64)
make -j"$(nproc)" Image modules

