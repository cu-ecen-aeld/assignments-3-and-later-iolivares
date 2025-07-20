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
    make -j$(nproc) Image
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

exit 

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

# TODO: Make device nodes

# TODO: Clean and build the writer utility

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO: Chown the root directory

# TODO: Create initramfs.cpio.gz
