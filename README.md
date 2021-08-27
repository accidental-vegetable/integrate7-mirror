# integrate7-mirror

This is a mirror of a Integrate7 script.
The original has been posted at:

https://www.sevenforums.com/installation-setup/417827-integrate7-script-automatically-download-slipstream-all-updates.html

Unfortunately, the original script, despite being `open-source` (author words),
does not seem to be in any git repository, and is released as a passworded archive and the old released versions are taken offline and are generally unavailable.

This makes it impossible to check for viruses without extracting archive and harder to follow script changes.

This repository will put each version in a separate branch, as many old versions unavailable from the source forum and the release timeline can't be recreated with versions I have.

The password for the archives was `Integrate2020` .

Unfortunately, the archives themselves (the latest ones for sure) were too large for GitHub, so aren't provided for reference.

The hashes of the archives are in `SHA256SUMS` and `SHA512SUMS` just in case for the reference.

# Differences
## DirectX
hotfixes/directx_Jun2010_redist.exe SHA512SUM IS NOT THE SAME!

The original file is according to virustotal.com:
File distributed by Square Enix Co. LTD

The downloaded file is according to virustotal.com:
File distributed by Microsoft

## Checking signatures and virustotal of Microsoft files can't download anymore.
Windows6.1-KB917607-x64.msu
Virustotal: Signed file, valid signature

Windows6.1-KB917607-x86.msu
Virustotal: Signed file, valid signature

Windows6.1-KB2533623-x64.msu
Virustotal: Signed file, valid signature

Windows6.1-KB2533623-x86.msu
Virustotal: Signed file, valid signature

KB2990941-v3-x64.msu
Virustotal: Signed file, valid signature

KB2990941-v3-x86.msu
Virustotal: Signed file, valid signature

# The hotfix lists

There are changes between 3.35 and 3.40:
```sh
diff hfixes_all.txt ../../Integrate7_3.40/hotfixes/hfixes_all.txt
161,163c161,163
< ; February 2021 Cumulative Update
< windows6.1-kb4601347-x86.msu http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/01/windows6.1-kb4601347-x86_53791324ad02cf747e8b8bce9d76d47a84de222f.msu
< windows6.1-kb4601347-x64.msu http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/01/windows6.1-kb4601347-x64_12d4c2f351e395f5285b32060899ef4d087db463.msu
---
> ; May 2021 Cumulative Update
> windows6.1-kb5003233-x86.msu http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/05/windows6.1-kb5003233-x86_d989ecc9f9e89fd854e739f9ac336c279a498968.msu
> windows6.1-kb5003233-x64.msu http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/05/windows6.1-kb5003233-x64_e51f18e0b70f455bc318123599af001b67344047.msu
```

AND

```sh
diff net4_all.txt ../../Integrate7_3.40/hotfixes/net4_all.txt 
34,35c34,35
< ndp48-kb4600944-x86.exe http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/01/ndp48-kb4600944-x86_648e45a1d0a6e44addeeaf441b63b53b0cab72a4.exe
< ndp48-kb4600944-x64.exe http://download.windowsupdate.com/c/msdownload/update/software/secu/2021/01/ndp48-kb4600944-x64_20a6a012e02c9d905f6f3a24850f1218bc849a26.exe
---
> ndp48-kb5001843-x86.exe http://download.windowsupdate.com/c/msdownload/update/software/updt/2021/04/ndp48-kb5001843-x86_3da1749fd02a079ba5d45d6d631fbb365054322c.exe
> ndp48-kb5001843-x64.exe http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/04/ndp48-kb5001843-x64_dc06d911dffd65ed01ac53c7d80f6764bf820496.exe

```

These are identical:
c49a646ed478ebc9a93bc37f696a9efdc7b46ab89db2dd1acf850cb005ef71c9  dx9.txt
3fb48405f59113e4731d6758804a755020334a3efafb72e87f01039ef901e7b8  ie11_all.txt


# Comparing old 2.21 vs 3.40_manual_download
>>> set(new) - set (old)
{'windows6.1-kb4592510-x64.msu', # Servicing stack update for Windows 7 SP1 and Server 2008 R2 SP1: December 8, 2020
 'ndp48-kb5001843-x64.exe',
 'windows6.1-kb2864202-x64.msu', # MS13-081: Description of the security update for USB drivers: October 8, 2013
 'windows6.1-kb5003233-x64.msu', # May 11, 2021—KB5003233 (Monthly Rollup)
 'Windows6.1-KB3118401-x64.msu', # Update for Universal C Runtime in Windows
 'directx_Jun2010_redist.exe', 
 'windows6.1-kb4578952-x64.msu'}
>>> set(old) - set (new)
{'ndp48-kb4532941-x64.exe', 
'windows6.1-kb4536952-x64.msu', # Servicing stack update for Windows 7 SP1 and Server 2008 R2 SP1: January 14, 2020
'windows6.1-kb3020369-x64.msu', # April 2015 servicing stack update for Windows 7 and Windows Server 2008 R2
'windows6.1-kb4534310-x64.msu', # January 14, 2020—KB4534310 (Monthly Rollup)
'windows6.1-kb4539602-x64.msu'} # Wallpaper set to Stretch is displayed as black in Windows 7 SP1 and Server 2008 R2 SP1

# DISM
The DISM directory contains executables with subversion 9600, which corresponds to Windows 8.1.
So these are from Windows ADK for Windows 8.1.
Unfortunately, it is not provided anymore by Microsoft for download.

The versions of DISM executables:
DISM/dism.exe (6.3.9600.17029)
DISM/imagex.exe (6.3.9600.17095)
DISM/pkgmgr.exe (6.3.9600.17029)
DISM/wimmountadksetupamd64.exe (6.3.9600.16384)
DISM/wimserv.exe (6.3.9600.17029)

All these executables are the same in Integrate7 versions checked (v2.21, v3.35, v3.40).

All the executable were manually checked by virustotal.com, all clear and have Microsoft signatures.
The rest of files were checked in an archive by virustotal.com and nothing was flagged.

sha256sum --check tools_virustotal_confirmed.sha256


In 2.21 version there was also wget for Adobe Flash Player
ExtraScripts/InstallFlashPlayer/wget.exe (GNU wget 1.19.4 buil on mingw32)
