#!/usr/bin/env sh

apk add --no-cache gcc musl-dev git autoconf make automake libtool libusb-dev eudev-dev linux-headers spawn-fcgi

git clone https://github.com/voltronic-inverter/fcgi-interface.git /opt/voltronic-fcgi-interface
cd /opt/voltronic-fcgi-interface/lib
./pull_libhidapi.sh
./pull_libserialport.sh
./pull_libfcgi2.sh

cd /opt/voltronic-fcgi-interface/lib/libhidapi/
./bootstrap
./configure --disable-dependency-tracking
make
make install

cd /opt/voltronic-fcgi-interface/lib/libserialport/
./autogen.sh
./configure
make
make install

cd /opt/voltronic-fcgi-interface/lib/libfcgi2/
./autogen.sh
./configure
make
make install

cd /opt/voltronic-fcgi-interface
make serial
make hidraw
make libusb

mv /opt/voltronic-fcgi-interface/voltronic_fcgi_serial /opt/voltronic_fcgi_serial
mv /opt/voltronic-fcgi-interface/voltronic_fcgi_hidraw /opt/voltronic_fcgi_hidraw
mv /opt/voltronic-fcgi-interface/voltronic_fcgi_libusb /opt/voltronic_fcgi_libusb

echo -e '#!/usr/bin/env sh\n\nwhile true; do\nspawn-fcgi -p 9001 -n /opt/voltronic_fcgi_serial\ndone' > /opt/voltronic_fcgi_serial_daemon
echo -e '#!/usr/bin/env sh\n\nwhile true; do\nspawn-fcgi -p 9002 -n /opt/voltronic_fcgi_hidraw\ndone' > /opt/voltronic_fcgi_hidraw_daemon
echo -e '#!/usr/bin/env sh\n\nwhile true; do\nspawn-fcgi -p 9003 -n /opt/voltronic_fcgi_libusb\ndone' > /opt/voltronic_fcgi_libusb_daemon
echo -e '#!/usr/bin/env sh\n\n/opt/voltronic_fcgi_serial_daemon &\n/opt/voltronic_fcgi_hidraw_daemon &\n/opt/voltronic_fcgi_libusb_daemon &\n\nwhile true; do\n  sleep 1h\ndone
' > /opt/voltronic_fcgi_daemon

chmod 775 /opt/voltronic_fcgi_serial
chmod 775 /opt/voltronic_fcgi_hidraw
chmod 775 /opt/voltronic_fcgi_libusb

chmod 775 /opt/voltronic_fcgi_serial_daemon
chmod 775 /opt/voltronic_fcgi_hidraw_daemon
chmod 775 /opt/voltronic_fcgi_libusb_daemon
chmod 775 /opt/voltronic_fcgi_daemon

rm -rf /opt/voltronic-fcgi-interface

apk del gcc musl-dev git autoconf make automake libtool linux-headers
