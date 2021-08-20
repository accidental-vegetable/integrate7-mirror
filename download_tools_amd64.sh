#! /bin/bash

# Create directories for the tools.
export DIR_NAME="Integrate7/tools/amd64"
mkdir -p $DIR_NAME

# Download Wget
# GNU Wget 1.20.3 built on mingw32
# wget --directory-prefix=$DIR_NAME https://eternallybored.org/misc/wget/1.20.3/64/wget.exe
## The latest version: 1.21.1
wget --directory-prefix=$DIR_NAME https://eternallybored.org/misc/wget/1.21.1/64/wget.exe

# Download & Extract NSudo
wget https://github.com/M2Team/NSudo/releases/download/6.1/NSudo_6.1.1811.18_All_Binary.zip
unzip -p NSudo_6.1.1811.18_All_Binary.zip "NSudo 6.1.1811.18/x64/NSudo.exe" > $DIR_NAME/NSudo.exe
rm NSudo_6.1.1811.18_All_Binary.zip

# Download & Extract 7-Zip
# 7-Zip Console 19.00 (19.0.0.0)
# The given 7-Zip seems to be a copy from installed 7-Zip, usually at C:\Program Files\7-Zip\
# 7z.exe : File distributed by LORENZ Bridge Software GmbH (According to www.virustotal.com)
# wget --directory-prefix=$DIR_NAME https://files.exefiles.com/7/7z.exe/619F7135621B50FD1900FF24AADE1524/7z.exe
# wget --directory-prefix=$DIR_NAME https://files.exefiles.com/7/7z.dll/72491C7B87A7C2DD350B727444F13BB4/7z.dll

# 7-Zip Setup, NOT ALTERNATIVE 7z.exe
wget https://raw.githubusercontent.com/ip7z/a/main/7z1900-x64.exe -O $DIR_NAME/7z-setup.exe

7zr e 7z-setup.exe 7z.exe 7z.dll
# OR

# file-roller -e "7z-setup" --force 7z-setup.exe
# mv 7z-setup/7z.exe ./7z.exe
# mv 7z-setup/7z.dll ./7z.dll
# rm -R 7z-setup
rm 7z-setup.exe

# For oscdimg.exe and DISM you need "The Windows® Automated Installation Kit (AIK) for Windows® 7" (1.8GB ISO file)
# https://www.microsoft.com/en-us/download/details.aspx?id=5753
# DISM is installed with Windows, and it is also distributed in the Windows Assessment and Deployment Kit (Windows ADK)
# THIS Windows AIK has oscdimg 2.55.0.1010, NOT the one used here.

# OSCDIMG 2.56 (2.56.0.1010)
# oscdimg.exe : File distributed by Microsoft (According to www.virustotal.com)
