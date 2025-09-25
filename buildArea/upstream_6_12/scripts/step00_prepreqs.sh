#!/usr/bin/env bash
set -euxo pipefail

# Build essentials & kernel deps
sudo apt-get update
sudo apt-get install -y \
  build-essential git curl wget unzip bc bison flex libssl-dev libelf-dev \
  dwarves pahole pkg-config ccache \
  qemu-system-arm qemu-system-misc qemu-system-aarch64 \
  gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu \
  libncurses-dev rsync cpio

# Go for syzkaller (>=1.20 recommended; Ubuntu 24.04 has 1.22)
sudo apt-get install -y golang

sudo apt-get install -y tmux ripgrep

