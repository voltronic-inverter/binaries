#!/usr/bin/env bash

TZ='Etc/UTC' DEBIAN_FRONTEND='noninteractive' apt-get install -y tzdata
apt-get install -y unzip

mkdir '/src/'
curl -L -o '/src/version_parser.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/version_parser.sh'
chmod 775 '/src/version_parser.sh'
curl -L -o '/src/repo_fetcher.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/repo_fetcher.sh'
chmod 775 '/src/repo_fetcher.sh'
/src/repo_fetcher.sh

VERSION_PATH=`/src/version_parser.sh`
mkdir "${VERSION_PATH}/linux/"
mkdir "${VERSION_PATH}/linux/arm"

apt-get install -y make gcc autoconf automake libtool pkg-config gcc-arm-linux-gnueabi binutils-arm-linux-gnueabi libusb-1.0-0-dev

# Install ARM udev binary

cp /etc/apt/sources.list /etc/apt/sources.list.old
rm /etc/apt/sources.list
curl -L -o '/etc/apt/sources.list' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/sources-arm-ubuntu.list'

cd /tmp
apt-get update
apt-get download libudev-dev:armhf
dpkg --force-all -i libudev-dev_175-0ubuntu9.10_armhf.deb
rm -rf /tmp/libudev-dev_175-0ubuntu9.10_armhf.deb

rm /etc/apt/sources.list
cp /etc/apt/sources.list.old /etc/apt/sources.list

curl -L -o '/usr/lib/arm-linux-gnueabihf/libudev.so.0.13.0' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/arm-linux-gnueabihf-libudev.so.0.13.0'
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
curl -L -o '/build/fcgi-interface/Makefile' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/linux/Makefile_arm'

make clean && make libserialport
mv -f '/build/fcgi-interface/voltronic_fcgi_libserialport' "${VERSION_PATH}/linux/arm/voltronic_fcgi_serial"

make clean && make hidapi-hidraw
mv -f '/build/fcgi-interface/voltronic_fcgi_hidapi_hidraw' "${VERSION_PATH}/linux/arm/voltronic_fcgi_usb"
