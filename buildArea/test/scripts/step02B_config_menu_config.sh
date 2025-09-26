#!/usr/bin/env bash
set -euxo pipefail
cd linux-6.12

#export ARCH=arm64
#export CROSS_COMPILE=aarch64-linux-gnu-

export ARCH=x86_64
unset CROSS_COMPILE

# Base config
make defconfig 

# Merge our fragment (ships with the kernel)
	./scripts/kconfig/merge_config.sh -m .config ../config/fuzzingKernelConfig.fragment
yes "" | make olddefconfig

# (Optional) Verify key symbols
for s in KCOV KASAN USB_USB_COMMON USB_DUMMY_HCD; do
  rg -N "^CONFIG_${s}=|^# CONFIG_${s} " .config || true
done

