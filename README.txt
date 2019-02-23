MichalOS
********

A 32-bit operating system based on MikeOS,
aimed to make it more advanced on the inside,
but simple and easy to use on the outside.

Special thanks to:
	- my classmates for reporting bugs and ideas
	- Michael Saunders (and all the MikeOS developers)
	- Joshua Beck

System requirements:
	- Intel 80386 or higher
	- At least 128kB RAM, 192kB recommended
	- A VGA card (EGA currently doesn't work)
	- A keyboard

Building the OS
***************

Windows:
	- Required programs:
		Imdisk
			32-bit: https://sourceforge.net/projects/imdisk-toolkit/files/20170706/ImDiskTk.exe
			64-bit: https://sourceforge.net/projects/imdisk-toolkit/files/20170706/ImDiskTk-x64.exe
		QEMU
			32-bit: https://qemu.weilnetz.de/w32/qemu-w32-setup-20180725.exe
			64-bit: https://qemu.weilnetz.de/w64/qemu-w64-setup-20180725.exe
	- To build, open the directory with MichalOS and run:
		build-windows.bat
	- If you prefer a cleaner MichalOS build (without example images and "music"), run:
		build-windows-clean.bat
	- If you just want to boot the image without rebuilding, open:
		boot.bat
Linux:
	- Required packages: "nasm", "dosfstools", "qemu"
	- To build: open the terminal, navigate to the directory that contains MichalOS and type:
		sudo ./build-linux
	- If you prefer a cleaner MichalOS build (without example images and "music"), type:
		sudo ./build-linux-clean
	(note: both of the commands listed above will ask for your password)
	- If you just want to boot the image without rebuilding, type:
		./boot.sh