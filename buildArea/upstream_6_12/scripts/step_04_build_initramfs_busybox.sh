#!/usr/bin/env bash
set -euxo pipefail

# Paths
ROOT="$(pwd)"
BUSYBOX_DIR="${ROOT}/busybox-src"
INITRD_DIR="${ROOT}/initramfs"
OUT="${ROOT}/initramfs.cpio.gz"

# Get BusyBox (shallow)
if [ ! -d "${BUSYBOX_DIR}" ]; then
  git clone --depth 1 https://busybox.net/git/busybox.git "${BUSYBOX_DIR}"
fi

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# Build static busybox
cd "${BUSYBOX_DIR}"
make distclean
make defconfig
# Force static binary to avoid libc hassle
scripts/config -e STATIC
make -j"$(nproc)" busybox

# Create initramfs tree
cd "${ROOT}"
rm -rf "${INITRD_DIR}"
mkdir -p "${INITRD_DIR}"/{bin,sbin,etc,proc,sys,dev,tmp,root,usr/bin,usr/sbin}
cp "${BUSYBOX_DIR}/busybox" "${INITRD_DIR}/bin/"

# Symlinks for busybox applets
pushd "${INITRD_DIR}/bin"
for a in sh mount dmesg cat echo ls mkdir mknod sleep uname modprobe; do
  ln -sf busybox "$a"
done
popd

# Minimal /init
cat > "${INITRD_DIR}/init" << 'EOF'
#!/bin/sh
set -eux

mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug

# Print dmesg marker
echo "[initramfs] booted"

# Drop to a shell so you can poke around or let syzkaller exec
exec /bin/sh
EOF
chmod +x "${INITRD_DIR}/init"

# Populate /dev
sudo mknod -m 666 "${INITRD_DIR}/dev/console" c 5 1 || true
sudo mknod -m 666 "${INITRD_DIR}/dev/null"    c 1 3 || true

# Pack
cd "${INITRD_DIR}"
find . -print0 | cpio --null -ov --format=newc | gzip -9 > "${OUT}"
echo "Wrote ${OUT}"

