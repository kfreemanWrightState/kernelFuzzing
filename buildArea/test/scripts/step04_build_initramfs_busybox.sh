#!/usr/bin/env bash
set -euo pipefail

# Minimal portable BusyBox initramfs builder for x86_64 (native build)
BUSYBOX_VERSION="${BUSYBOX_VERSION:-1.36.1}"
ARCH="${ARCH:-x86_64}"            # informational only; BusyBox uses native gcc when CROSS not set
CROSS_COMPILE="${CROSS_COMPILE:-}" # empty => native compiler

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BB_DIR="${ROOT_DIR}/busybox-${BUSYBOX_VERSION}"
BB_TARBALL="${ROOT_DIR}/busybox-${BUSYBOX_VERSION}.tar.bz2"
ROOTFS="${BB_DIR}/rootfs"
INITRAMFS="${BB_DIR}/initramfs.cpio.gz"

# tools check
command -v gcc >/dev/null || { echo "gcc not found"; exit 1; }
command -v make >/dev/null || { echo "make not found"; exit 1; }
command -v cpio >/dev/null || { echo "cpio not found"; exit 1; }
command -v gzip >/dev/null || { echo "gzip not found"; exit 1; }

# fetch/extract busybox if needed
if [ ! -d "$BB_DIR" ]; then
  if [ -f "$BB_TARBALL" ]; then
    echo "[*] Extracting ${BB_TARBALL}"
    tar -xf "$BB_TARBALL" -C "$ROOT_DIR"
  else
    echo "[*] Downloading BusyBox ${BUSYBOX_VERSION}"
    TARBALL="busybox-${BUSYBOX_VERSION}.tar.bz2"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSLO "https://busybox.net/downloads/${TARBALL}"
    else
      wget -q "https://busybox.net/downloads/${TARBALL}"
    fi
    tar -xf "${TARBALL}" -C "${ROOT_DIR}"
  fi
else
  echo "[*] Using existing ${BB_DIR}"
fi

cd "${BB_DIR}"

# clean old state
make mrproper

# default config (native)
make defconfig

# prefer static busybox (optional; remove if static link fails)
if grep -q '^# CONFIG_STATIC is not set' .config; then
  sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
fi

# disable tc applet to avoid header mismatches
if grep -q '^CONFIG_TC=y' .config; then
  sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config
fi
awk '/^CONFIG_FEATURE_TC_/ && /=y$/{sub(/=.*/,""); print "s/^" $0 "=y/# " $0 " is not set/"}' .config | sed -i -f - .config || true

# build & install (native)
make -j"$(nproc)"
rm -rf "${ROOTFS}"
make CONFIG_PREFIX="${ROOTFS}" install

# minimal initramfs tree
mkdir -p "${ROOTFS}"/{proc,sys,dev,run,tmp,root}
chmod 1777 "${ROOTFS}/tmp"

# minimal /init to get a shell (customize later if you want switch_root)
cat > "${ROOTFS}/init" <<'SH'
#!/bin/sh
set -eu
echo "[initramfs] up"
mount -t proc none /proc || true
mount -t sysfs none /sys || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
exec /bin/sh
SH
chmod +x "${ROOTFS}/init"

# pack initramfs
( cd "${ROOTFS}" && find . -print0 | LC_ALL=C sort -z | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > "${INITRAMFS}" )

echo "[✓] initramfs built: ${INITRAMFS}"
file "${ROOTFS}/bin/busybox" || true


