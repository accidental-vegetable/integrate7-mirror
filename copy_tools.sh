#! /bin/bash

modprobe nbd max_part=8

qemu-nbd --connect=/dev/nbd0 /var/lib/libvirt/images/win7-sp1-airgapped.qcow2

mkdir /mnt/somepoint

fdisk /dev/nbd0 -l
# This one ("nbd0p2") is the main NTFS partition in this case.
# mount /dev/nbd0p1 /mnt/somepoint/
mount /dev/nbd0p2 /mnt/somepoint/

# To copy AIK Tools for Integrate7 script
export DIR_NAME="~/Win-reinstall/Integrate7_v3.40_min"
cp -R /mnt/somepoint/Program\ Files/Windows\ AIK/Tools/amd64/oscdimg.exe $DIR_NAME/tools/amd64/

cp -R /mnt/somepoint/Program\ Files/Windows\ AIK/Tools/amd64/Servicing/* $DIR_NAME/tools/amd64/DISM/
mv $DIR_NAME/tools/amd64/DISM/Dism.exe $DIR_NAME/tools/amd64/DISM/dism.exe

# To copy out of VM the resulting slipstreamed Windows ISO
# cp /mnt/somepoint/Integrate7_v3.40_min/Win*.iso ~/ISOs/
# OR
# cp /mnt/somepoint/Integrate7_v3.40_min/Windows7_x64_en-US.iso ~/ISOs/
# chown -R user:group ~/ISOs/Win*iso

umount /mnt/somepoint/
rmdir /mnt/somepoint
qemu-nbd --disconnect /dev/nbd0
rmmod nbd