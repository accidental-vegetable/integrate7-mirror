#! /bin/bash

# Create directories for the hotfixes.
export DIR_NAME="Integrate7/hotfixes/NVMe"
mkdir -p $DIR_NAME

# Confirmed
echo "Check Microsoft (ORIGINAL) confirmed"
sha512sum --check hotfixes_microsoft_confirmed.sha512
# Not confirmed yet
echo "Check Virustotal confirmed"
sha512sum --check hotfixes_virustotal_confirmed.sha512

echo "Check Virustotal confirmed SHA256"
sha256sum --check hotfixes_virustotal_confirmed.sha256
