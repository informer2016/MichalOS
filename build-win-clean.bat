echo off
cls

echo Creating new MichalOS floppy image...
cd disk_images
del michalos.*
fsutil file createnew michalos.flp 1474560
cd ..

echo Assembling bootloader...
cd source\bootload
..\..\windows_tools\nasm.exe -O0 -f bin -o bootload.bin bootload.asm
cd ..

echo Assembling MichalOS kernel...
..\windows_tools\nasm.exe -O0 -f bin -o michalos.sys system.asm

echo Assembling MichalOS 2nd-stage bootloader...
..\windows_tools\nasm.exe -O0 -f bin -o boot.sys boot.asm

echo Assembling programs...
cd programs
for %%i in (*.app) do del %%i
for %%i in (*.asm) do ..\windows_tools\nasm.exe -O0 -fbin %%i -o %%~ni.app
cd ..

echo Adding bootloader to disk image...
cd disk_images
..\windows_tools\partcopy.exe ..\source\bootload\bootload.bin 0 512 michalos.flp
cd ..

echo Mounting disk image...
imdisk -a -f disk_images\michalos.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy source\boot.sys b:\
copy source\michalos.sys b:\
copy source\sys\*.sys b:\
copy programs\*.app b:\
copy programs\*.bas b:\
copy programs\*.dat b:\

cd disk_images
copy michalos.flp michalos.img
cd ..

echo Unmounting disk image...
imdisk -D -m B:

boot.bat

echo Done!

pause