#!/usr/bin/env bash

# Fetch all the repos
mkdir '/src'
curl -L -o '/src/repo_fetcher.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/repo_fetcher.sh'
chmod 775 '/src/repo_fetcher.sh'
/src/repo_fetcher.sh

# Determine target platform
BUILD_STATE=0
uname -m | grep 'i686' > /dev/null 2>/dev/null
if [ $? -eq 0 ]; then
  BUILD_STATE=$(( $BUILD_STATE + 1 ))
else
  BUILD_STATE=$(( $BUILD_STATE + 2 ))
fi

if [ $BUILD_STATE -eq 1 ]; then
  echo 'Building i686 Linux binaries'
elif [ $BUILD_STATE -eq 2 ]; then
  echo 'Building x86-64 Linux binaries'
else
  echo 'Unknown build state'
  exit 1
fi

# Install udev; We will not be linking to it statically
yum install -y libudev libudev-devel
if [ $BUILD_STATE -eq 0 ]; then
  ln -s /usr/lib/pkgconfig/libudev.pc /hbb_exe/lib/pkgconfig/
else
  ln -s /usr/lib64/pkgconfig/libudev.pc /hbb_exe/lib/pkgconfig/
fi

# Start compiling
source /hbb_exe/activate

# Build fcgi2
cd /build/fcgi-interface/lib/fcgi2
./autogen.sh
./configure
make

# Build libserialport
cd /build/fcgi-interface/lib/libvoltronic/lib/libserialport
./autogen.sh
./configure
make

# Build libusb
cd /build/fcgi-interface/lib/libvoltronic/lib/libusb/
./autogen.sh
./configure
make
make install
if [ $BUILD_STATE -eq 0 ]; then
  ln -s /usr/local/lib/pkgconfig/libusb-1.0.pc /hbb_exe/lib/pkgconfig/
else
  ln -s /usr/local/lib/pkgconfig/libusb-1.0.pc /hbb_exe/lib/pkgconfig/
fi

# Build HID API
cd /build/fcgi-interface/lib/libvoltronic/lib/hidapi
./bootstrap
./configure

# Required because of possible missing defines for HID
curl -L -o /build/fcgi-interface/lib/libvoltronic/lib/hidapi/hid_extra.h 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/hid_extra.h'
sed '/#include "hidapi.h"/a #include "hid_extra.h"' /build/fcgi-interface/lib/libvoltronic/lib/hidapi/linux/hid.c > /tmp/hid.c
mv -f '/tmp/hid.c' '/build/fcgi-interface/lib/libvoltronic/lib/hidapi/linux/hid.c'

make

# Build fcgi-interface
cd /build/fcgi-interface
rm -f Makefile
curl -L -o '/build/fcgi-interface/Makefile' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/Makefile'

make clean && make libserialport
if [ $BUILD_STATE -eq 0 ]; then
  mv -f '/build/fcgi-interface/voltronic_fcgi_libserialport' '/io/voltronic_fcgi_libserialport_i686'
else
  mv -f '/build/fcgi-interface/voltronic_fcgi_libserialport' '/io/voltronic_fcgi_libserialport_x86-64'
fi

make clean && make hidapi-hidraw
if [ $BUILD_STATE -eq 0 ]; then
  mv -f '/build/fcgi-interface/voltronic_fcgi_hidapi_hidraw' '/io/voltronic_fcgi_hidapi_hidraw_i686'
else
  mv -f '/build/fcgi-interface/voltronic_fcgi_hidapi_hidraw' '/io/voltronic_fcgi_hidapi_hidraw_x86-64'
fi
