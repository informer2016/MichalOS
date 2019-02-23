#!/bin/sh

echo ">>> Lauching MichalOS/2 with 4MB of RAM, an Adlib sound card and a 486 CPU..."
qemu-system-i386 -cpu 486 -m 4M -k en-us -soundhw pcspk,adlib -name "MichalOS/2" -fda disk_images/michalos.img -vga std
exit
