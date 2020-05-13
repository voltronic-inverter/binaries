#!/usr/bin/env bash

VERSION=`cat '/build/fcgi-interface/include/version.h' | grep 'VOLTRONIC_FCGI_VERSION' | grep -v '#ifndef' | cut -d '"' -f 2 2>/dev/null`
if [[ $? -eq 0 ]]; then
  mkdir "/io/${VERSION} 1>/dev/null 2>/dev/null"
  if [[ $? -eq 0 ]]; then
    echo "/io/${VERSION}"
    exit 0
  fi
fi

exit 1
