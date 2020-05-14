#!/usr/bin/env bash

echo "Starting linux-arm voltronic-fcgi build"

if [[ -d '/io/' ]]; then
  echo "Output directory /io exists"
else
  echo "Output directory /io doest not exist"
  exit 1
fi

echo "Installing required packages"
TZ='Etc/UTC' DEBIAN_FRONTEND='noninteractive' apt-get install -y tzdata 1>/dev/null 2>/dev/null
apt-get install -y unzip 1>/dev/null 2>/dev/null

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
TARGET_ARCHITECTURE="arm"
VERSION=`/io/src/version_parser.sh`
if [[ $? -ne 0 ]]; then
  echo "Could not determine voltronic-fcgi version"
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

echo "Installing build tools"
apt-get install -y make gcc autoconf automake libtool pkg-config gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi libusb-1.0-0-dev 1>/dev/null 2>/dev/null

# Install ARM udev binary

cp /etc/apt/sources.list /etc/apt/sources.list.old
rm /etc/apt/sources.list
curl -sSL -o '/etc/apt/sources.list' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/sources-arm-ubuntu.list'

cd /tmp
apt-get update 1>/dev/null 2>/dev/null
apt-get download libudev-dev:armhf 1>/dev/null 2>/dev/null
dpkg --force-all -i libudev-dev_175-0ubuntu9.10_armhf.deb 1>/dev/null 2>/dev/null
rm -rf /tmp/libudev-dev_175-0ubuntu9.10_armhf.deb

rm /etc/apt/sources.list
cp /etc/apt/sources.list.old /etc/apt/sources.list

curl -sSL -o '/usr/lib/arm-linux-gnueabihf/libudev.so.0.13.0' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/arm-linux-gnueabihf-libudev.so.0.13.0'
rm '/usr/lib/arm-linux-gnueabihf/libudev.so'
ln -s '/usr/lib/arm-linux-gnueabihf/libudev.so.0.13.0' '/usr/lib/arm-linux-gnueabihf/libudev.so'
ln -s '/usr/lib/arm-linux-gnueabihf/pkgconfig/libudev.pc' '/usr/lib/x86_64-linux-gnu/pkgconfig/libudev.pc'

# Build fcgi2
cd '/build/fcgi-interface/lib/fcgi2'
./autogen.sh
./configure --host=arm-linux-gnueabi --target=arm-linux-gnueabi
make

# Build libserialport
cd '/build/fcgi-interface/lib/libvoltronic/lib/libserialport'
sed '/AC_PROG_CC/a AM_PROG_CC_C_O' '/build/fcgi-interface/lib/libvoltronic/lib/libserialport/configure.ac' > /tmp/configure.ac
mv -f /tmp/configure.ac '/build/fcgi-interface/lib/libvoltronic/lib/libserialport/configure.ac'
./autogen.sh
./configure --host=arm-linux-gnueabi --target=arm-linux-gnueabi
make

#Build hidapi
cd '/build/fcgi-interface/lib/libvoltronic/lib/hidapi'
./bootstrap
./configure --host=arm-linux-gnueabi --target=arm-linux-gnueabi
make

# Build fcgi-interface
cd '/build/fcgi-interface'
rm -f Makefile
curl -sSL -o '/build/fcgi-interface/Makefile' "https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/Makefile_${TARGET_ARCHITECTURE}"

make clean && make libserialport
mv -f '/build/fcgi-interface/voltronic_fcgi_libserialport' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_serial"

make clean && make hidapi-hidraw
mv -f '/build/fcgi-interface/voltronic_fcgi_hidapi_hidraw' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_usb"
