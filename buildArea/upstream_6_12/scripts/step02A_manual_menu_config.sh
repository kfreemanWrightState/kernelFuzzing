#!/usr/bin/env bash
set -euxo pipefail
cd linux-6.12

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Start from a reasonable base
make defconfig

# Let you edit interactively
make menuconfig

