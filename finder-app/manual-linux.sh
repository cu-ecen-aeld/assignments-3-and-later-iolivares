#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

# Use https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git for the linux kernel source directory. 
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
# Kernel branch/tag
KERNEL_VERSION=v5.15.163

BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))

ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

# Take a single argument outdir which is the location on the filesystem where the output files should be placed.
# If not specified, your script should use /tmp/aeld as outdir
OUTDIR=/tmp/aeld
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

#  Create a directory outdir if it doesn’t exist.  Fail if the directory could not be created.
if ! mkdir -p ${OUTDIR}; then
    echo "Error: could not create output directory ${OUTDIR}"
    exit 1
fi

cd "$OUTDIR"

# Use git to clone the linux kernel source tree if it doesn’t exist in outdir.
# Use the `--depth 1` command line argument with git if you’d like to minimize download time
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    # Checkout the tag specified
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make defconfig
    make kvm_guest.config
    make -j$(nproc) 
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p ${OUTDIR}/rootfs/{bin,dev,etc,lib,lib64,home,proc,sys,sbin,tmp,usr,usr/bin,usr/sbin,var}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}

    # TODO:  Configure busybox
    echo "Configure busybox"
    make distclean
    make defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
echo "Make and install busybox"
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install 

${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
echo "Copying busybox library dependencies"
toolchainlib_dir=$(dirname $(which ${CROSS_COMPILE}readelf))/../aarch64-none-linux-gnu/libc

cp -v $toolchainlib_dir/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib
cp -v $toolchainlib_dir/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64
cp -v $toolchainlib_dir/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64
cp -v $toolchainlib_dir/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64

# TODO: Make device nodes
echo "Creating null and console devices"
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
echo 
cd $FINDER_APP_DIR
make clean
make

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -v ./writer ./autorun-qemu.sh ./finder-test.sh ${OUTDIR}/rootfs/home

# TODO: Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

