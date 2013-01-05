#!/bin/bash

NVIDIA_LIB32DIR=/usr/lib/nvidia
NVIDIA_LIB64DIR=/usr/lib64/nvidia
ARCH=$(uname -m)
IS_64=false
[[ $ARCH == x86_64 ]] && IS_64=true

if ! yum -y install wget binutils gcc kernel-devel mesa-libGL mesa-libGLU; then
    echo "The package manager failed to install dependencies for the nVidia driver"
    exit 2
fi

echo "Getting latest nVidia drivers version"

if $IS_64; then
    BASEDIR="ftp://download.nvidia.com/XFree86/Linux-x86_64/"
    NVIDIA_LIBDIR="$NVIDIA_LIB64DIR"
elif [ "$ARCH" = "i686" ]; then
    BASEDIR="ftp://download.nvidia.com/XFree86/Linux-x86/"
    NVIDIA_LIBDIR="$NVIDIA_LIB32DIR"
fi

LATEST=`wget -q -O - ${BASEDIR}/latest.txt | cut -f2 -d" " | tr -d '\n\r'`
TMPDIR="$(mktemp -d)"

# The driver filename, e.g. NVIDIA-Linux-x86-280.13.run
NV_DRIVER="${LATEST##*/}"

wget -nv ${BASEDIR}/${LATEST} -O "${TMPDIR}/${NV_DRIVER}"

NV_DRIVERS_VERSION="${LATEST%%/*}"

echo "Latest NVidia drivers version is ${NV_DRIVERS_VERSION}"

# Extract the binary
sh "${TMPDIR}/${NV_DRIVER}" --target "${TMPDIR}/nvidia" -x

rm -rf "$NVIDIA_LIB32DIR"
rm -rf "$NVIDIA_LIB64DIR"

NVIDIA_ARGS=( --no-x-check
            --no-nouveau-check
             -s
            --x-prefix="$NVIDIA_LIBDIR"
            --x-library-path="$NVIDIA_LIBDIR"
            --installer-prefix="$NVIDIA_LIBDIR"
            --x-module-path="$NVIDIA_LIBDIR/xorg/modules"
            --utility-prefix="$NVIDIA_LIBDIR" --utility-libdir=.
            --opengl-prefix="$NVIDIA_LIBDIR" --opengl-libdir=. )

if [ "$ARCH" = "x86_64" ]; then
    NVIDIA_ARGS[${#NVIDIA_ARGS[@]}]="--compat32-prefix=$NVIDIA_LIB32DIR"
    NVIDIA_ARGS[${#NVIDIA_ARGS[@]}]=--compat32-libdir=.
fi

"${TMPDIR}/nvidia/nvidia-installer" "${NVIDIA_ARGS[@]}"

# Make sure we can run the nvidia X-server without all kind of library issues
# See also http://us.download.nvidia.com/XFree86/Linux-x86/<version>/README/installedcomponents.html
# or http://us.download.nvidia.com/XFree86/Linux-x86_64/<version>/README/installedcomponents.html
rm -f "$NVIDIA_LIBDIR/xorg/modules/libnvidia-wfb.so.${NV_DRIVERS_VERSION}"
rm -f "$NVIDIA_LIBDIR/xorg/modules/libnvidia-wfb.so.1"
rm -f "$NVIDIA_LIBDIR/xorg/modules/libwfb.so"

# cleanup
rm -rf "${TMPDIR}"

# Make sure we still have 3D on our Intel card (also for developers)
yum -y reinstall libvdpau mesa-libGL mesa-libGL-devel xorg-x11-server-Xorg