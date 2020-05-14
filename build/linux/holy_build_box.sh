#!/usr/bin/env bash

if [[ -d '/io/' ]]; then
  echo "Output directory /io exists"
else
  echo "Output directory /io doest not exist"
  exit 1
fi

# Fetch all the repos
ls '/io/src/shared_file_fetcher.sh' 1>/dev/null 2>/dev/null
if [[ $? -ne 0 ]]; then
  mkdir '/io/src'
  curl -sSL -o '/io/src/shared_file_fetcher.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/shared_file_fetcher.sh'
  chmod 775 '/io/src/shared_file_fetcher.sh'
fi

/io/src/shared_file_fetcher.sh
if [[ $? -ne 0 ]]; then
  echo "Could not successfully fetch shared files"
  exit 1
fi

# Compilation properties
TARGET_PLATFORM="linux"
TARGET_ARCHITECTURE="<unknown>"
VERSION=`/io/src/version_parser.sh`
if [[ $? -ne 0 ]]; then
  echo "Could not determine voltronic-fcgi version"
  exit 1
fi

# Determine target platform
BUILD_STATE=0
uname -m | grep 'i686' > /dev/null 2>/dev/null
if [ $? -eq 0 ]; then
  BUILD_STATE=$(( $BUILD_STATE + 1 ))
else
  BUILD_STATE=$(( $BUILD_STATE + 2 ))
fi

if [ $BUILD_STATE -eq 1 ]; then
  TARGET_ARCHITECTURE="i686"
elif [ $BUILD_STATE -eq 2 ]; then
  TARGET_ARCHITECTURE="amd64"
else
  echo 'Unknown build state'
  exit 1
fi

mkdir -p "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}"
chmod 775 "/io/${VERSION}"
chmod 775 "/io/${VERSION}/${TARGET_PLATFORM}"
chmod 775 "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}"
ls "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}" 1>/dev/null 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo "Could not create output path"
  exit 1
fi

echo "Building ${TARGET_PLATFORM} ${TARGET_ARCHITECTURE} v${VERSION} binaries"

# Install udev; We will not be linking to it statically
yum install -y libudev libudev-devel 1>/dev/null 2>/dev/null
if [ $BUILD_STATE -eq 1 ]; then
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
ln -s /usr/local/lib/pkgconfig/libusb-1.0.pc /hbb_exe/lib/pkgconfig/

# Build HID API
cd /build/fcgi-interface/lib/libvoltronic/lib/hidapi
./bootstrap
./configure

# Required because of possible missing defines for HID
curl -sSL -o '/build/fcgi-interface/lib/libvoltronic/lib/hidapi/hid_extra.h' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/hid_extra.h'
sed '/#include "hidapi.h"/a #include "hid_extra.h"' /build/fcgi-interface/lib/libvoltronic/lib/hidapi/linux/hid.c > /tmp/hid.c
mv -f '/tmp/hid.c' '/build/fcgi-interface/lib/libvoltronic/lib/hidapi/linux/hid.c'

make

# Build fcgi-interface
cd /build/fcgi-interface
rm -f Makefile
curl -sSL -o '/build/fcgi-interface/Makefile' "https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/Makefile_x86"

make clean && make libserialport
mv -f '/build/fcgi-interface/voltronic_fcgi_libserialport' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_serial"

make clean && make hidapi-hidraw
mv -f '/build/fcgi-interface/voltronic_fcgi_hidapi_hidraw' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_usb"
