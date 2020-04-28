#!/usr/bin/env bash

# Fetch everything required to complete a build

fetch_repo() {
  rm -rf '/tmp/unzip_temp' 1>/dev/null 2>/dev/null
  mkdir '/tmp/unzip_temp' 1>/dev/null 2>/dev/null
  mkdir '/src' 1>/dev/null 2>/dev/null
  mkdir '/build' 1>/dev/null 2>/dev/null

  OUTPUT_NAME="${1}"
  DESTINATION="${2}"
  REPO_NAME="${3}"

  find "/src/${OUTPUT_NAME}.zip" -maxdepth 1 -type f
  if [ $? -ne 0 ]; then
    echo "Fetching ${OUTPUT_NAME} repo"
    curl -o "/src/${OUTPUT_NAME}.zip" -L "${REPO_NAME}"
  fi

  echo "Decompressing ${OUTPUT_NAME} repo"
  unzip "/src/${OUTPUT_NAME}.zip" -d '/tmp/unzip_temp/'

  echo "Moving to /build/${OUTPUT_NAME}"
  mv "/tmp/unzip_temp/`ls -1 '/tmp/unzip_temp/'`" "${DESTINATION}"

  rm -rf '/tmp/unzip_temp' 1>/dev/null 2>/dev/null
}

# Get fcgi-interface
fetch_repo 'fcgi-interface' '/build/fcgi-interface' 'https://github.com/voltronic-inverter/fcgi-interface/archive/master.zip'
rm -rf '/build/fcgi-interface/lib/fcgi2' 1>/dev/null 2>/dev/null
rm -rf '/build/fcgi-interface/lib/libvoltronic' 1>/dev/null 2>/dev/null

# Get libvoltronic
fetch_repo 'libvoltronic' '/build/fcgi-interface/lib/libvoltronic' 'https://github.com/jvandervyver/libvoltronic/archive/master.zip'
rm -rf '/build/fcgi-interface/lib/libvoltronic/lib/hidapi' 1>/dev/null 2>/dev/null
rm -rf '/build/fcgi-interface/lib/libvoltronic/lib/libserialport' 1>/dev/null 2>/dev/null
rm -rf '/build/fcgi-interface/lib/libvoltronic/lib/libusb' 1>/dev/null 2>/dev/null

# Get fcgi2
fetch_repo 'fcgi2' '/build/fcgi-interface/lib/fcgi2' 'https://github.com/FastCGI-Archives/fcgi2/archive/master.zip'

# Get HID API
fetch_repo 'hidapi' '/build/fcgi-interface/lib/libvoltronic/lib/hidapi' 'https://github.com/libusb/hidapi/archive/master.zip'

# Get libusb
fetch_repo 'libusb' '/build/fcgi-interface/lib/libvoltronic/lib/libusb' 'https://github.com/libusb/libusb/archive/master.zip'

# Get libserialport
fetch_repo 'libserialport' '/build/fcgi-interface/lib/libvoltronic/lib/libserialport' 'https://sigrok.org/gitweb/?p=libserialport.git;a=snapshot;h=HEAD;sf=zip'
