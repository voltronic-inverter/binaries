#!/usr/bin/env bash

# Install dependencies required to fetch the repos
TZ='Etc/UTC' DEBIAN_FRONTEND='noninteractive' apt-get install -y tzdata
apt-get install -y unzip

# Get repo fetching script & fetch the repos
mkdir '/src/'
curl -L -o '/src/repo_fetcher.sh' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/repo_fetcher.sh'
chmod 775 '/src/repo_fetcher.sh'
/src/repo_fetcher.sh

echo "Starting build"

# Install build dependencies
apt-get install -y make gcc autoconf automake libtool pkg-config mingw-w64

# Start the build loop
LOOP_COUNT=0
while [ $LOOP_COUNT -le 1 ]; do
  LOOP_COUNT=$(( $LOOP_COUNT + 1 ))

  rm -rf '/build' 1>/dev/null 2>/dev/null

  if [ $LOOP_COUNT -eq 1 ]; then
    echo "Building i686 binaries"
  elif [ $LOOP_COUNT -eq 2 ]; then
    echo "Building x86-64 binaries"
  else
    echo "Unsupported build mode"
    exit 1
  fi
  /src/repo_fetcher.sh

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
  if [ $LOOP_COUNT -eq 1 ]; then
    curl -L -o '/build/fcgi-interface/Makefile' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/windows/Makefile_x86'
  else
    curl -L -o '/build/fcgi-interface/Makefile' 'https://raw.githubusercontent.com/voltronic-inverter/binaries/master/build/windows/Makefile_x86_64'
  fi

  make clean && make libserialport
  if [ $LOOP_COUNT -eq 1 ]; then
    mv -f '/build/fcgi-interface/libserialport.exe' '/io/voltronic_fcgi_libserialport_i686.exe'
  else
    mv -f '/build/fcgi-interface/libserialport.exe' '/io/voltronic_fcgi_libserialport_x86-64.exe'
  fi

  make clean && make hidapi
  if [ $LOOP_COUNT -eq 1 ]; then
    mv -f '/build/fcgi-interface/hidapi.exe' '/io/voltronic_fcgi_hidapi_hidraw_i686.exe'
  else
    mv -f '/build/fcgi-interface/hidapi.exe' '/io/voltronic_fcgi_hidapi_hidraw_x86-64.exe'
  fi
done

echo "Build complete"
