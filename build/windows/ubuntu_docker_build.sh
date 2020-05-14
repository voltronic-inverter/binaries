#!/usr/bin/env bash

if [[ -d '/io/' ]]; then
  echo "Output directory /io exists"
else
  echo "Output directory /io doest not exist"
  exit 1
fi

# Install dependencies required to fetch the repos
TZ='Etc/UTC' DEBIAN_FRONTEND='noninteractive' apt-get install -y tzdata
apt-get install -y unzip

# Fetch all the repos
ls '/io/src/shared_file_fetcher.sh' 1>/dev/null 2>/dev/null
if [[ $? -ne 0 ]]; then
  mkdir '/io/src'
  curl -sSL -o '/io/src/shared_file_fetcher.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/shared_file_fetcher.sh'
  chmod 775 '/io/src/shared_file_fetcher.sh'
  /io/src/shared_file_fetcher.sh
  if [[ $? -ne 0 ]]; then
    echo "Could not successfully fetch shared files"
    exit 1
  fi
fi

# Compilation properties
TARGET_PLATFORM="windows"
TARGET_ARCHITECTURE=""
VERSION=`/io/src/version_parser.sh`
if [[ $? -ne 0 ]]; then
  echo "Could not determine voltronic-fcgi version"
  exit 1
fi

mkdir -p "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}"
ls '/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}' 1>/dev/null 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo "Could not create output path"
  exit 1
fi

# Install build dependencies
apt-get install -y make gcc autoconf automake libtool pkg-config mingw-w64

# Start the build loop
LOOP_COUNT=0
while [ $LOOP_COUNT -le 1 ]; do
  LOOP_COUNT=$(( $LOOP_COUNT + 1 ))

  rm -rf '/build' 1>/dev/null 2>/dev/null

  if [ $LOOP_COUNT -eq 1 ]; then
    TARGET_ARCHITECTURE="i686"
    echo "Building i686 binaries"
  elif [ $LOOP_COUNT -eq 2 ]; then
    TARGET_ARCHITECTURE="amd64"
  else
    echo "Unsupported build mode"
    exit 1
  fi
  /io/src/shared_file_fetcher.sh

  echo "Building ${TARGET_PLATFORM} ${TARGET_ARCHITECTURE} binaries"

  # Build libserialport
  cd '/build/fcgi-interface/lib/libvoltronic/lib/libserialport'
  ./autogen.sh
  if [ $LOOP_COUNT -eq 1 ]; then
    ./configure --host=i686-w64-mingw32 --target=xi686-w64-mingw32 --disable-dependency-tracking
  else
    ./configure --host=x86_64-w64-mingw32 --target=x86_64-w64-mingw32 --disable-dependency-tracking
  fi
  make

  # Build HIDAPI
  cd '/build/fcgi-interface/lib/libvoltronic/lib/hidapi'
  ./bootstrap
  if [ $LOOP_COUNT -eq 1 ]; then
    ./configure --host=i686-w64-mingw32 --target=i686-w64-mingw32
  else
    ./configure --host=x86_64-w64-mingw32 --target=x86_64-w64-mingw32
  fi
  make

  # Build fcgi2
  cd '/build/fcgi-interface/lib/fcgi2'
  ./autogen.sh
  if [ $LOOP_COUNT -eq 1 ]; then
    ./configure --host=i686-w64-mingw32 --target=i686-w64-mingw32
  else
    ./configure --host=x86_64-w64-mingw32 --target=x86_64-w64-mingw32
  fi
  make

  # Build fcgi-interface
  cd '/build/fcgi-interface'
  rm -f Makefile
  curl -sSL -o '/build/fcgi-interface/Makefile' "https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/windows/Makefile_${TARGET_ARCHITECTURE}"

  make clean && make libserialport
  mv -f '/build/fcgi-interface/libserialport.exe' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_serial.exe"

  make clean && make hidapi
  mv -f '/build/fcgi-interface/hidapi.exe' "/io/${VERSION}/${TARGET_PLATFORM}/${TARGET_ARCHITECTURE}/voltronic_fcgi_usb.exe"

done

echo "Build complete"
