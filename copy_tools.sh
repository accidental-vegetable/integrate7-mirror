#! /bin/bash

modprobe nbd max_part=8

qemu-nbd --connect=/dev/nbd0 /var/lib/libvirt/images/win7-sp1-airgapped.qcow2

fdisk /dev/nbd0 -l

mkdir /mnt/somepoint
# mount /dev/nbd0p1 /mnt/somepoint/
mount /dev/nbd0p2 /mnt/somepoint/

export DIR_NAME="~/Win-reinstall/Integrate7_v3.40_min"
cp -R /mnt/somepoint/Program\ Files/Windows\ AIK/Tools/amd64/oscdimg.exe $DIR_NAME/tools/amd64/

cp -R /mnt/somepoint/Program\ Files/Windows\ AIK/Tools/amd64/Servicing/* $DIR_NAME/tools/amd64/DISM/
mv $DIR_NAME/tools/amd64/DISM/Dism.exe $DIR_NAME/tools/amd64/DISM/dism.exe


umount /mnt/somepoint/
rmdir /mnt/somepoint
qemu-nbd --disconnect /dev/nbd0
rmmod nbd