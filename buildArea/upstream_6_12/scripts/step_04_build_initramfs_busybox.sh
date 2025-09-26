#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
BUSYBOX_VERSION="1.36.1"
CROSS_COMPILE="aarch64-linux-gnu-"
BUILD_DIR="build/busybox"
INITRAMFS_DIR="build/initramfs"
OUTPUT_FILE="initramfs.cpio.gz"

# --- Script functions ---
download_busybox() {
    echo "Downloading BusyBox version $BUSYBOX_VERSION..."
    wget -nc "https://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2"
    tar -xf "busybox-$BUSYBOX_VERSION.tar.bz2"
}

check_cross_compiler() {
    echo "Checking for cross-compiler: ${CROSS_COMPILE}gcc"
    if ! command -v "${CROSS_COMPILE}gcc" &> /dev/null; then
        echo "Error: Cross-compiler '${CROSS_COMPILE}gcc' not found in PATH."
        echo "Please install it, for example on Debian/Ubuntu: sudo apt install crossbuild-essential-arm64"
        exit 1
    fi
}

configure_busybox() {
    echo "Configuring BusyBox for AArch64..."
    cd "busybox-$BUSYBOX_VERSION"
    
    # Create a default configuration for the target architecture
    make defconfig ARCH=arm64
    
    # Modify the config using sed
    # Build a static binary (no shared libraries)
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    # Set the cross-compiler prefix
    sed -i "s/# CONFIG_CROSS_COMPILER_PREFIX is not set/CONFIG_CROSS_COMPILER_PREFIX=\"${CROSS_COMPILE}\"/" .config
    
    # Disable the 'tc' applet
    echo "Disabling CONFIG_TC..."
    sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config
    sed -i 's/CONFIG_FEATURE_TC_INGRESS=y/# CONFIG_FEATURE_TC_INGRESS is not set/' .config
}

build_and_install_busybox() {
    echo "Building BusyBox for AArch64..."
    make -j$(nproc) ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}"
    
    echo "Installing BusyBox to temporary build directory..."
    make install CONFIG_PREFIX="${BUILD_DIR}" ARCH=arm64 CROSS_COMPILE="${CROSS_COMPILE}"
}

create_initramfs() {
    echo "Creating initramfs..."
    # Clean up previous build directories
    rm -rf "${INITRAMFS_DIR}" "${OUTPUT_FILE}"
    mkdir -p "${INITRAMFS_DIR}"
    
    # Copy the installed BusyBox files
    cp -a "${BUILD_DIR}/"* "${INITRAMFS_DIR}/"

    # Create essential directories
    cd "${INITRAMFS_DIR}"
    mkdir -p {dev,proc,sys,etc}

    # Create a basic 'init' script
    cat > init << EOF
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
exec /bin/sh
EOF
    chmod +x init

    echo "Building compressed cpio archive..."
    find . -print0 | cpio --null -ov --format=newc | gzip -9 > "../../${OUTPUT_FILE}"
    echo "Successfully created ${OUTPUT_FILE}"
}

# --- Main script execution ---
echo "Starting BusyBox build for AArch64..."

# Prepare directories
mkdir -p build

# Run the functions in order
check_cross_compiler
download_busybox
configure_busybox
build_and_install_busybox
create_initramfs

echo "Done. The initramfs is available as ${OUTPUT_FILE}."

