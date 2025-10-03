#!/usr/bin/env bash
set -euxo pipefail

# Step 1: Install Dependencies
sudo apt update
sudo apt install -y build-essential clang flex g++ gawk gcc-multilib gettext git \
libncurses5-dev libssl-dev python3 python3-setuptools python3-distutils-extra rsync unzip zlib1g-dev

# Step 2: Clone OpenWRT Source
if [ ! -d openwrt ]; then
  git clone --depth 1 --branch v24.10.2 https://git.openwrt.org/openwrt/openwrt.git
fi

cd openwrt

# Step 3: Update and Install Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Step 4: Apply Config
cp ../openwrt_x86_64_ver2.config .config
#make defconfig
#make -j $(nproc) kernel_menuconfig

make -j $(nproc) defconfig download clean world

cd bin/targets/x86/64

gunzip -k openwrt-x86-64-generic-ext4-combined.img.gz

qemu-img create -f qcow2 data.qcow2 3G

qemu-system-x86_64 \
  -accel tcg -cpu max -smp 2 -m 2048 \
  -M q35 \
  -drive file=openwrt-x86-64-generic-ext4-combined.img,format=raw,if=none,id=d0 \
  -device ide-hd,drive=d0,bus=ide.0 \
  -drive file=data.qcow2,format=qcow2,if=none,id=d1 \
  -device ide-hd,drive=d1,bus=ide.1 \
  -nic user,model=e1000,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
  -serial mon:stdio -nographic


#qemu-system-x86_64 \
#  -enable-kvm -cpu host -smp 2 -m 2048 \
#  -M q35 \
#  -drive file=openwrt-x86-64-generic-ext4-combined.img,format=raw,if=none,id=d0 \
#  -device ide-hd,drive=d0,bus=ide.0 \
#  -drive file=data.qcow2,format=qcow2,if=none,id=d1 \
#  -device ide-hd,drive=d1,bus=ide.1 \
#  -nic user,model=e1000,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
#  -serial mon:stdio -nographic
