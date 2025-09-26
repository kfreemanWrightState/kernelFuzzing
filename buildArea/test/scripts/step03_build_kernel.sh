#!/usr/bin/env bash
set -euxo pipefail
cd linux-6.12

export ARCH=x86_64
unset CROSS_COMPILE

# Build the kernel image for x86_64
# The x86 kernel image is arch/x86/boot/bzImage
make -j"$(nproc)" bzImage modules

echo "Built: arch/x86/boot/bzImage"
