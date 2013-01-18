#!/bin/bash

NVIDIA_LIB32DIR=/usr/lib/nvidia
NVIDIA_LIB64DIR=/usr/lib64/nvidia
ARCH=$(uname -m)
IS_64=false
[[ $ARCH == x86_64 ]] && IS_64=true

if ! yum -y install rpm wget binutils gcc kernel-devel mesa-libGL mesa-libGLU libbsd-devel dkms libbsd glibc-devel libX11-devel help2man autoconf git tar glib2 glib2-devel kernel-headers automake gtk2-devel; then
    echo "The package manager failed to install dependencies for the nVidia driver"
    exit 2
fi

#Resources Download
mkdir resources
cd resources

wget https://github.com/downloads/Bumblebee-Project/Bumblebee/bumblebee-3.0.1.tar.gz
wget https://github.com/downloads/Bumblebee-Project/bbswitch/bbswitch-0.5.tar.gz

#bbswitch module install
tar xvzf bbswitch-0.5.tar.gz
cp -Rv  bbswitch-0.5 /usr/src
ln -s /usr/src/bbswitch-0.5/dkms/dkms.conf /usr/src/bbswitch-0.5/dkms.conf
dkms add -m bbswitch -v 0.5
dkms build -m bbswitch -v 0.5
dkms install -m bbswitch -v 0.5

#OpenGL with VirtualGl installation

wget http://downloads.sourceforge.net/project/virtualgl/VirtualGL/2.3.2/VirtualGL-2.3.2.x86_64.rpm
wget http://downloads.sourceforge.net/project/virtualgl/VirtualGL/2.3.2/VirtualGL-2.3.2.i386.rpm

yum -y localinstall VirtualGL-2.3.2.x86_64.rpm
yum -y localinstall VirtualGL-2.3.2.i386.rpm

#yum -y install glibc.i686 libX11.i686 libXau.i686 libXdamage.i686 libXext.i686 libXfixes.i686 libXv.i686 libXxf86vm.i686 libdrm.i686 libgcc.i686 libpciaccess.i686 libselinux.i686 libstdc++.i686 libxcb.i686 mesa-libGL.i686 mesa-libGLU.i686 mesa-libglapi.i686 nss-softokn-freebl.i686 pcre.i686

#rpm -ivh --replacefiles VirtualGL-2.3.2.x86_64.rpm 
#rpm -ivh --replacefiles VirtualGL-2.3.2.i386.rpm 


#bumblebee instalation

tar xvzf bumblebee-3.0.1.tar.gz
cd bumblebee-3.0.1
./configure --prefix=/usr --sysconfdir=/etc 
make 
make install
cd ..
cp ../Configuracion/bumblebeed.service /lib/systemd/system 

groupadd bumblebee
echo "Ingrese su nombre de usuario:"
read nombre
gpasswd -a $nombre bumblebee

systemctl enable bumblebeed.service
systemctl start bumblebeed.service

cd ..


#NVIDIA Driver instalation
echo "Getting 310.19 nVidia drivers version"
TMPDIR="$(mktemp -d)"

mkdir Driver
cd Driver

if $IS_64; then
    NVIDIA_LIBDIR="$NVIDIA_LIB64DIR"    
    wget http://es.download.nvidia.com/XFree86/Linux-x86_64/310.19/NVIDIA-Linux-x86_64-310.19.run
    NV_DRIVER="NVIDIA-Linux-x86_64-310.19.run"
elif [ "$ARCH" = "i686" ]; then
    NVIDIA_LIBDIR="$NVIDIA_LIB32DIR"
    NV_DRIVER="NVIDIA-Linux-x86-310.19.run"
    wget http://es.download.nvidia.com/XFree86/Linux-x86/310.19/NVIDIA-Linux-x86-310.19.run
fi

cd ..

cp Driver/"${NV_DRIVER}" "${TMPDIR}"


# Extract the binary
sh "${TMPDIR}/${NV_DRIVER}" --target "${TMPDIR}/nvidia" -x

rm -rf "$NVIDIA_LIB32DIR"
rm -rf "$NVIDIA_LIB64DIR"

NVIDIA_ARGS=( --no-x-check
            --no-nouveau-check
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

#Copy configuration
if [ "$ARCH" = "x86_64" ]; then
   cp -f Configuracion/* /etc/bumblebee/
fi
if [ "$ARCH" = "i686" ]; then
   echo "Your arch required manual configuration of /etc/bumblebee/bumblebee.conf and /etc/bumblebee/xorg-nvidia.conf"
fi

# Make sure we still have 3D on our Intel card (also for developers)
#yum -y reinstall libvdpau mesa-libGL mesa-libGL-devel xorg-x11-server-Xorg

if  rpm -q libvdpau; then
	yum -y reinstall libvdpau
elif ! rpm -q libvdpau; then
	yum -y install libvdpau
fi

if  rpm -q mesa-libGL; then
	yum -y reinstall mesa-libGL
elif ! rpm -q mesa-libGL; then
	yum -y install mesa-libGL
fi

if  rpm -q mesa-libGL-devel; then
	yum -y reinstall mesa-libGL-devel
elif ! rpm -q mesa-libGL-devel; then
	yum -y install mesa-libGL-devel
fi

if  rpm -q xorg-x11-server-Xorg; then
	yum -y reinstall xorg-x11-server-Xorg
elif ! rpm -q xorg-x11-server-Xorg; then
	yum -y install xorg-x11-server-Xorg
fi
