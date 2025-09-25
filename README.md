# kernelFuzzing
Project to fuzz the kernel for embedded Linux distributions.

## Table of Contents

- [Project Description](#project-description)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Project Description

This project aim is to address the issue of the looking for vulnerabilities in embedded devices. 

## Installation

### Prerequisites

- Ubuntu 24.04

After installing ubuntu 24.04 on a host device or a virtual machine, run the following command 
to install the necessary packages. 

```bash
sudo apt-get update 
sudo apt-get upgrade -y
sudo apt-get install -y git make gcc g++ python3 rsync gawk gettext\
    libncurses-dev zlib1g-dev qemu-system-arm qemu-utils \
    build-essential gcc-arm-linux-gnueabihf \
    libguestfs-tools python3 python3-pip python3-setuptools swig
    
pip3 install setuptools
   
````

### Steps

1. Clone the repository:
   ```bash
   https://github.com/kfreemanWrightState/kernelFuzzing.git
````

2. Navigate into the project directory:

   ```bash
   cd kernelFuzzing
   ```
   
3. Build the OpenWrt image with sanitizers included. (NOTE: This step has already been completed and can be skipped but was included for documentation purposes) 
For this example an image for the Banana Pi will be installed from source. The image will
contain kernel sanitizers that will assist in fuzzing.
    a. Navigate to the Banana Pi Build Area
        ```bash
        cd ~/kernelFuzzing/buildOpenWrt/bananaPi
        ```   
    b. Next clone the openWrt source code from the git repository. 
       ```bash
        git clone https://git.openwrt.org/openwrt/openwrt.git
        cd openwrt
        git fetch --tags
        git checkout v23.05.3
        ./scripts/feeds update -a && ./scripts/feeds install -a
       ```
    c. Next setup up the build config file using the menu config tool. 
       ```bash
       make menuconfig
       ```
       In the Menuconfig set the following settings
       -Target System: Allwinner ARM SoCs
       -Subtarget: Cortex A7
       -Target Profile: Sinovoip Banana Pi M2 Ultra
       Also make sure to enable the kernel sanitizers:
       - Global build settings → Kernel build options:
            -Compile the kernel with KASan: runtime memory debugger
            -Compile the kernel with code coverage for fuzzing
       Afterwards you will be prompted to create a new menuconfig file. Save this 
       config file.
        
    d. After the process builds, you should be able run the newly built image in QEMU
	mkdir working 
	cp bin/targets/sunxi/cortexa7/openwrt-sunxi-cortexa7-sinovoip_bananapi-m2-ultra-ext4-sdcard.img.gz working
	cp ./build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-sunxi_cortexa7/vmlinux.debug working
	cd working
	nm vmlinux.debug > kallsyms
	gunzip openwrt-sunxi-cortexa7-sinovoip_bananapi-m2-ultra-ext4-sdcard.img.gz 
	qemu-img resize openwrt-sunxi-cortexa7-sinovoip_bananapi-m2-ultra-ext4-sdcard.img 2G
	qemu-system-arm -M bpim2u -nographic \
	-nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443 \
	-sd openwrt-sunxi-cortexa7-sinovoip_bananapi-m2-ultra-ext4-sdcard.img
	
   e. Configure networking for the Banana Pi 
   	```bash
		edit the /etc/config/network file to include the following
		config interface 'loopback'
			option device 'lo'
			option proto 'static'
			option ipaddr '127.0.0.1'
			option netmask '255.0.0.0'

		config globals 'globals'
			option ula_prefix 'fd3c:a7a4:f476::/48'

		config device
			option name 'br-lan'
			option type 'bridge'

		config interface 'lan'
			option device 'br-lan'
			option proto 'static'
			option ipaddr '192.168.1.1'
			option netmask '255.255.255.0'
			option ip6assign '60'

		config interface 'wan'
			option device 'eth0'
			option proto 'dhcp'
		```

		/etc/init.d/network restart

		udhcpc -i eth0


cat /etc/resolv.conf

upstream 
sudo apt update
sudo apt install -y build-essential git bc bison flex libelf-dev libssl-dev \
  dwarves pahole pkg-config ccache clang lld \
  qemu-system-x86 qemu-utils \
  golang-go python3-minimal unzip curl \
  libcap-ng-dev libnl-3-dev libnl-genl-3-dev
  
mkdir -p ~/kernelFuzzing/buildArea/upstream_6_12/ 
cd ~/kernelFuzzing/buildArea/upstream_6_12/ 
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-v6.12
cd linux-v6.12
git checkout v6.12
	

## Usage

Explain how to use your project once it's set up. Include code examples, CLI commands, or instructions for interacting with your application.

Example:

```bash
npm start  # for starting a Node.js app
python app.py  # for running a Python app
```

## License

This project is licensed under the [MIT License](LICENSE) - see the [LICENSE](LICENSE) file for details.

```

### Key Sections to Modify:
- **Project Name:** Replace it with the actual name of your project.
- **Description:** Provide a short and long description of what your project does.
- **Installation Instructions:** Add any dependencies or setup steps.
- **Usage:** Explain how someone can run or use your project, including code examples or command-line instructions.
- **Contributing Guidelines:** If you want others to contribute to your project, you can add steps for how they can do so.
- **License:** Include any license your project uses (MIT, GPL, etc.).

Feel free to modify it according to your needs! Let me know if you'd like to adjust anything specific.
```

