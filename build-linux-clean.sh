#!/bin/sh

# This script assembles the MichalOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Linux)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files

# (If you need to blank the floppy image: 'mkdosfs disk_images/michalos.flp')


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi

echo ">>> Creating new MichalOS floppy image..."
rm disk_images/michalos.flp
mkdosfs -C disk_images/michalos.flp 1440 || exit

echo ">>> Assembling bootloader..."

nasm -O0 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit

echo ">>> Assembling MichalOS kernel..."

cd source
nasm -O0 -w+orphan-labels -f bin -o michalos.sys system.asm || exit

echo ">>> Assembling MichalOS 2nd-stage bootloader..."

nasm -O0 -w+orphan-labels -f bin -o boot.sys boot.asm || exit

cd ..

echo ">>> Assembling programs..."

cd programs

for i in *.asm
do
	nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.app || exit
done

cd ..

echo ">>> Adding bootloader to floppy image..."

dd status=noxfer conv=notrunc if=source/bootload/bootload.bin of=disk_images/michalos.flp || exit

echo ">>> Copying MichalOS kernel, bootloader and programs..."

rm -rf tmp-loop

mkdir tmp-loop
mount -t vfat disk_images/michalos.flp tmp-loop

cp source/boot.sys tmp-loop/
cp source/michalos.sys tmp-loop/
cp programs/*.app programs/*.bas programs/*.dat tmp-loop/
cp source/sys/*.sys tmp-loop/

sleep 0.2

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit

rm -rf tmp-loop

echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/michalos.iso
mkisofs -quiet -V 'MICHALOS' -input-charset iso8859-1 -o disk_images/michalos.iso -b michalos.flp disk_images/ || exit

echo ">>> Copying some stuff..."
cp disk_images/michalos.flp /media/michal/Documents/Software/DOS/

echo '>>> Done!'
