#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

KERNEL="${ROOT_DIR}/linux-6.12/arch/x86/boot/bzImage"
INITRD="${ROOT_DIR}/busybox-1.36.1/initramfs.cpio.gz"

[ -f "${KERNEL}" ] || { echo "Missing kernel: ${KERNEL}"; exit 2; }
[ -f "${INITRD}" ] || { echo "Missing initramfs: ${INITRD}"; exit 2; }

# Force software emulation (TCG). Multi-threaded TCG helps a bit.
# Remove pti mitigations inside the VM for a little extra speed.
exec qemu-system-x86_64 \
  -accel tcg,thread=multi \
  -smp 2 \
  -m 1536 \
  -cpu max \
  -kernel "${KERNEL}" \
  -initrd "${INITRD}" \
  -append "console=ttyS0 root=/dev/ram0 rdinit=/init nokaslr pti=off" \
  -nographic \
  -serial mon:stdio \
  -device nec-usb-xhci,id=xhci \
  -device usb-ehci,id=ehci \
  -device usb-kbd \
  -device usb-tablet


