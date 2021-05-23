@echo off
TITLE Windows 7 Integrator
CLS

::
:: Author: Wojciech Keller
:: Version: 3.40
:: License: free
::

:: ============================================================================================================
:: -------------- Start of Configuration Section --------------------------------------------------------------
:: ============================================================================================================

:: Download and integrate all post-SP1 updates up to May 2021
 set InstallHotfixes=1

:: Additional updates, installed silently after Windows Setup Ends
::
  :: - Silently install NET Framework 4.8
   set IncludeNET4=1
  :: - Execute queued NET compilations (takes some extra time after setup, but then Windows works faster)
   set ExecuteNGEN=0
  :: - Silently install DirectX 9 June 2010
   set IncludeDX9=1



:: Apply custom patches (from corresponding section below)
:: and integrate files from folder add_these_files_to_Windows\(x86 or x64)
 set ApplyCustPatches=1

  :: Custom Patches sub-sections:
  :: - Set default NTP time server instead of time.windows.com
   set NTPserver=pool.ntp.otg
  :: - Disable Internet Connection Checking if you are paranoid about your privacy
   set DisableInternetConnectionChecking=0
  :: - Remove System Restore
   set RemoveSR=1
  :: - Remove Windows Defender
   set RemoveDefender=1
  :: - Disable User Account Control
   set DisableUAC=1
  :: - Disable All Event Logs (sometimes causes problems with Microsoft SQL or similar software)
   set DisableEventLogs=0
  :: - Disable ciphering protocols older than TLS 1.2
   set DisableObsoleteSSL=0
  :: - Removes legacy VGA video driver, which is recommended for UEFI class 3 firmare
  ::   You MUST! provide vendor Video Card driver when legacy VGA is removed
   set RemoveLegacyVGA=0



:: Integrate drivers:
::  - from add_these_drivers_to_Installer\(x86 or x64) to boot.wim
::  - from add_these_drivers_to_Windows\(x86 or x64) to install.wim
::  - from add_these_drivers_to_Recovery\(x86 or x64) to winRE.wim (inside install.wim)
 set AddDrivers=1


:: Cleanup Images (redundant unless you manualy slipstreamed Service Pack 1)
 set CleanupImages=0


:: Repack/recompress boot.wim and install.wim to save some space
 set RepackImages=1

:: Split install.wim if its size exceed 4 GB
 set SplitInstallWim=1

:: Create ISO image or leave installer files in DVD folder
 set CreateISO=1


:: ============================================================================================================
:: ------------- End of Configuration Section -----------------------------------------------------------------
:: ============================================================================================================



:: ============================================================================================================


REM Check admin rights
fsutil dirty query %systemdrive% >nul 2>&1
if ERRORLEVEL 1 (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO The script needs Administrator permissions!
 ECHO.
 ECHO Please run as Administrator or disable User Account Control.
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)


REM Check parenthesis in script PATH, which brakes subsequent for loops
set incorrectPath=0

echo "%~dp0%" | findstr "(" >nul 2>&1
if "%ERRORLEVEL%"=="0" set incorrectPath=1
echo "%~dp0%" | findstr ")" >nul 2>&1
if "%ERRORLEVEL%"=="0" set incorrectPath=1

if not "%incorrectPath%"=="0" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO The script cannot be run from this location!
 ECHO Current location contatins parenthesis in the PATH.
 ECHO.
 ECHO Please copy and run script from Desktop or another directory!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)


set MountRequired=0
if not "%InstallHotfixes%"=="0" set MountRequired=1
if not "%ApplyCustPatches%"=="0" set MountRequired=1
if not "%AddDrivers%"=="0" set MountRequired=1
if not "%CleanupImages%"=="0" set MountRequired=1


set "HostArchitecture=x86"
If exist "%WinDir%\SysWOW64" set "HostArchitecture=amd64"


set Win10ISOName=
set Win10ImageArchitecture=
for /f "delims=" %%i in ('dir /b /o-n "%~dp0Win*10*.iso" 2^>nul') do (set "Win10ISOName=%%i")


set ISOName=
for /f "delims=" %%i in ('dir /b /o-n "%~dp0*.iso" 2^>nul') do (
 if not "%%i"=="%Win10ISOName%" set "ISOName=%%i"
)


if "%ISOName%"=="" (
 if not exist "%~dp0DVD\sources\install.wim" (
  ECHO.
  ECHO.
  ECHO ================================================================
  ECHO ISO/DVD File not found in main script directory!
  ECHO.
  ECHO Please copy Windows 7 ISO DVD to the same location as Integrate7
  ECHO ================================================================
  ECHO.
  PAUSE >NUL
  goto end
 )
)


if not "%ISOName%"=="" (
 ECHO.
 ECHO.
 ECHO ===============================================================================
 ECHO Unpacking ISO/DVD image: "%ISOName%" to DVD directory...
 ECHO ===============================================================================
 ECHO.

 rd /s /q "%~dp0DVD" >nul 2>&1
 mkdir "%~dp0DVD" >nul 2>&1

 "%~dp0tools\%HostArchitecture%\7z.exe" x -y -o"%~dp0DVD" "%~dp0%ISOName%"
)


if not exist "%~dp0DVD\sources\install.wim" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Install.wim not found inside DVD source image!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

if not exist "%~dp0DVD\sources\boot.wim" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Boot.wim not found inside DVD source image!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)



set ImageStart=1
REM Number of Windows 7 editions inside ISO image
for /f "tokens=2 delims=: " %%i in ('start "" /b "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" ^| findstr /i Index') do (set ImageCount=%%i)


REM CPU architecture of Windows 7 ISO
for /f "tokens=2 delims=: " %%a in ('start "" /b "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%ImageStart% ^| findstr /i Architecture') do (set ImageArchitecture=%%a)
set PackagesArchitecture=amd64
if "%ImageArchitecture%"=="x86" set PackagesArchitecture=x86

REM Set ESU variables
set "EsuCom=amd64_microsoft-windows-s..edsecurityupdatesai_31bf3856ad364e35_6.1.7603.25000_none_caceb5163345f228"
set "EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E312E373630332E32353030302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D616D6436342C2076657273696F6E53636F70653D4E6F6E537853"
set "EsuHsh=45D0AE442FD92CE32EE1DDC38EA3B875EAD9A53D6A17155A10FA9D9E16BEDEB2"
set "EsuFnd=windowsfoundation_31bf3856ad364e35_6.1.7601.17514_615fdfe2a739474c"
set "EsuKey=amd64_microsoft-windows-s..edsecurityupdatesai_31bf3856ad364e35_none_0e8b36cfce2fb332"
if "%ImageArchitecture%"=="x86" (
 set "EsuCom=x86_microsoft-windows-s..edsecurityupdatesai_31bf3856ad364e35_6.1.7603.25000_none_6eb019927ae880f2"
 set "EsuIdn=4D6963726F736F66742D57696E646F77732D534C432D436F6D706F6E656E742D457874656E64656453656375726974795570646174657341492C2043756C747572653D6E65757472616C2C2056657273696F6E3D362E312E373630332E32353030302C205075626C69634B6579546F6B656E3D333162663338353661643336346533352C2050726F636573736F724172636869746563747572653D7838362C2076657273696F6E53636F70653D4E6F6E537853"
 set "EsuHsh=343B7E8DE2FE932E2FA1DB0CDFE69BB648BEE8E834B41728F1C83A12C1766ECB"
 set "EsuFnd=windowsfoundation_31bf3856ad364e35_6.1.7601.17514_0541445eeedbd616"
 set "EsuKey=x86_microsoft-windows-s..edsecurityupdatesai_31bf3856ad364e35_none_b26c9b4c15d241fc"
)

REM Language of Windows 7 ISO
for /f "tokens=1 delims= " %%a in ('start "" /b "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%ImageStart% ^| findstr /i "(Default)"') do (set ImageLanguage=%%a)
for /f "tokens=1 delims= " %%a in ('echo %ImageLanguage%') do (set ImageLanguage=%%a)

REM Check Windows images
set checkErrors=0
for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%%i | findstr /i Architecture | findstr /i "%ImageArchitecture%" >nul 2>&1
 if ERRORLEVEL 1 set checkErrors=1
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%%i | find /i "Name :" | find /i "Windows 7" >nul 2>&1
 if ERRORLEVEL 1 set checkErrors=1
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%%i | findstr /i "(Default)" | findstr /i "%ImageLanguage%" >nul 2>&1
 if ERRORLEVEL 1 set checkErrors=1
)

if not "%checkErrors%"=="0" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO This script supports only original Windows 7 images!
 ECHO.
 ECHO Mixed images with multiple OSes, multiple langauges
 ECHO or multiple architectures are not supported!
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)


setlocal ENABLEDELAYEDEXPANSION
ECHO.
ECHO.
ECHO ================================================================
ECHO Found the following images in ISO/DVD:
ECHO.
set ImageIndexes=
for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 set "ImageIndexes=!ImageIndexes!%%i"
 ECHO.
 ECHO Index: %%i
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%%i | find /i "Name :"
 ECHO Architecture: %ImageArchitecture%
 ECHO Language: %ImageLanguage%
)
ECHO.
ECHO ================================================================
ECHO.


if "%ImageStart%"=="%ImageCount%" goto skipSelectImage

CHOICE /C A%ImageIndexes% /M "Choose image index (A = All)"
set /a ImageIndex=%ERRORLEVEL%-1

if %ImageIndex% GEQ 1 (
 if not "%ImageStart%"=="%ImageCount%" (
  ECHO.
  ECHO.
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Export-Image /SourceImageFile:"%~dp0DVD\sources\install.wim" /SourceIndex:%ImageIndex% /DestinationImageFile:"%~dp0DVD\sources\install_index_%ImageIndex%.wim" /CheckIntegrity
  move /y "%~dp0DVD\sources\install_index_%ImageIndex%.wim" "%~dp0DVD\sources\install.wim" >nul 2>&1
  ECHO.
  SET ImageStart=1
  SET ImageCount=1
 )
)

:skipSelectImage


if not "%Win10ISOName%"=="" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Found Windows 10 ISO image!
 ECHO.
 ECHO Name: "%Win10ISOName%"
 ECHO ================================================================
 
 ECHO.
 ECHO Unpacking installer files to "Win10_Installer" directory....
 ECHO.

 rd /s /q "%~dp0Win10_Installer" >nul 2>&1
 mkdir "%~dp0Win10_Installer" >nul 2>&1
 mkdir "%~dp0Win10_Installer\DVD" >nul 2>&1
 mkdir "%~dp0Win10_Installer\EFI_Boot" >nul 2>&1
 mkdir "%~dp0Win10_Installer\mount" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\7z.exe" x -y -o"%~dp0Win10_Installer\DVD" "%~dp0%Win10ISOName%"
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Mount-Wim /WimFile:"%~dp0Win10_Installer\DVD\sources\install.wim" /index:1 /MountDir:"%~dp0Win10_Installer\mount"
 xcopy "%~dp0Win10_Installer\mount\Windows\Boot\*" "%~dp0Win10_Installer\EFI_Boot\" /e /s /y >nul 2>&1
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Unmount-Wim /MountDir:"%~dp0Win10_Installer\mount" /discard
 del /q /f "%~dp0Win10_Installer\EFI_Boot\*.ini"  >nul 2>&1
 rd /s /q "%~dp0Win10_Installer\mount" >nul 2>&1
 del /q /f "%~dp0Win10_Installer\DVD\sources\install.wim" >nul 2>&1
 del /q /f "%~dp0Win10_Installer\DVD\sources\install*.swm" >nul 2>&1
 
 ECHO.
 ECHO.
 ECHO Done.
 ECHO.
)


if exist "%~dp0Win10_Installer\DVD\sources\boot.wim" (
 for /f "tokens=2 delims=: " %%a in ('start "" /b "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0Win10_Installer\DVD\sources\boot.wim" /Index:1 ^| findstr /i Architecture') do (set Win10ImageArchitecture=%%a)
)

if "%Win10ImageArchitecture%"=="%ImageArchitecture%" (

 ECHO.
 ECHO Replacing Windows 7 installer with Windows 10 installer...
 ECHO.

 move /y "%~dp0DVD\sources\install.wim" "%~dp0Win10_Installer" >nul 2>&1
 rd /s /q "%~dp0DVD" >nul 2>&1
 xcopy "%~dp0Win10_Installer\DVD\*" "%~dp0DVD\" /e /s /y >nul 2>&1
 move /y "%~dp0Win10_Installer\install.wim" "%~dp0DVD\sources" >nul 2>&1
 ECHO.
 ECHO Done.
 ECHO.

)

del /q /f "%~dp0DVD\sources\ei.cfg" >nul 2>&1

xcopy "%~dp0ExtraScripts\*" "%~dp0DVD\ExtraScripts\" /e /s /y >nul 2>&1


if "%MountRequired%"=="0" goto skipMount

for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Mounting image with index %%i
 ECHO Mount directory: %~dp0mount\%%i
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\install.wim" /Index:%%i | find /i "Name :"
 ECHO ================================================================
 ECHO.

 rd /s/q "%~dp0mount\%%i" >NUL 2>&1
 mkdir "%~dp0mount\%%i" >NUL 2>&1
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Mount-Wim /WimFile:"%~dp0DVD\sources\install.wim" /index:%%i /MountDir:"%~dp0mount\%%i"


 REM Apply UEFI fix to DVD by getting bootmgr from mounted point
 if "%ImageArchitecture%"=="x64" (
  if not "%Win10ImageArchitecture%"=="%ImageArchitecture%" (
   if exist "%~dp0mount\%%i\Windows\Boot\EFI\bootmgfw.efi" (
    mkdir "%~dp0DVD\efi\boot" >nul 2>&1
    copy /b /y "%~dp0mount\%%i\Windows\Boot\EFI\bootmgfw.efi" "%~dp0DVD\efi\boot\bootx64.efi" >nul 2>&1
   )
  )
 )

)


if not "%InstallHotfixes%"=="1" goto skipHotfixes


ECHO.
ECHO.
ECHO ================================================================
ECHO Downloading missing Windows 7 Updates...
ECHO ================================================================
ECHO.


type "%~dp0hotfixes\hfixes_all.txt" | find /i "%ImageArchitecture%" > "%~dp0hotfixes\hfixes_%ImageArchitecture%.txt"
type "%~dp0hotfixes\ie11_all.txt" | find /i "%ImageArchitecture%" | find /i "%ImageLanguage%" > "%~dp0hotfixes\ie11_%ImageArchitecture%_%ImageLanguage%.txt"

if not "%IncludeNET4%"=="0" (
 REM NET 4 Main Installer
 type "%~dp0hotfixes\net4_all.txt" | findstr /i /c:"\-ENU." > "%~dp0hotfixes\net4_main.txt"
 REM NET 4 Language Pack
 type "%~dp0hotfixes\net4_all.txt" | findstr /i /c:"%ImageLanguage%" > "%~dp0hotfixes\net4_langpack_%ImageLanguage%.txt"
 REM NET 4 Updates
 type "%~dp0hotfixes\net4_all.txt" | findstr /i /c:"\-%ImageArchitecture%." > "%~dp0hotfixes\net4_hfixes_%ImageArchitecture%.txt"
)



cd /d "%~dp0hotfixes"

FOR /F "eol=; tokens=1,2*" %%i in (hfixes_%ImageArchitecture%.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"
FOR /F "eol=; tokens=1,2*" %%i in (ie11_%ImageArchitecture%_%ImageLanguage%.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"

if not "%IncludeNET4%"=="0" (
 REM NET 4 Main Installer
 FOR /F "eol=; tokens=1,2*" %%i in (net4_main.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"
 REM NET 4 Language Pack
 set Net4LangPackFile=
 FOR /F "eol=; tokens=1,2*" %%i in (net4_langpack_%ImageLanguage%.txt) do (
  if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"
  set "Net4LangPackFile=%%i"
 )
 REM NET 4 Updates
 FOR /F "eol=; tokens=1,2*" %%i in (net4_hfixes_%ImageArchitecture%.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"
)

if not "%IncludeDX9%"=="0" FOR /F "eol=; tokens=1,2*" %%i in (dx9.txt) do if not exist "%~dp0hotfixes\%%i" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "%%i" "%%j"


REM Restore Title Bar changed by wget
TITLE Windows 7 Integrator

cd /d "%~dp0"

del /q /f "%~dp0hotfixes\hfixes_%ImageArchitecture%.txt" >nul 2>&1
del /q /f "%~dp0hotfixes\ie11_%ImageArchitecture%_%ImageLanguage%.txt" >nul 2>&1

if not "%IncludeNET4%"=="0" (
 del /q /f "%~dp0hotfixes\net4_main.txt" >nul 2>&1
 del /q /f "%~dp0hotfixes\net4_langpack_%ImageLanguage%.txt" >nul 2>&1
 del /q /f "%~dp0hotfixes\net4_hfixes_%ImageArchitecture%.txt" >nul 2>&1
)


ECHO.
ECHO Done.
ECHO.



set SetupCompleteCMD=
if not "%IncludeNET4%"=="0" set SetupCompleteCMD=1
if not "%IncludeDX9%"=="0" set SetupCompleteCMD=1

if not "%SetupCompleteCMD%"=="1" goto skipSetupCompleteCMD
 mkdir "%~dp0DVD\sources\$oem$\$$\Setup\Scripts" >nul 2>&1
 mkdir "%~dp0DVD\Updates" >nul 2>&1
 echo @ECHO OFF>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo FOR %%%%I IN (C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%%%I:\Updates\ndp48-x86-x64-allos-enu.exe" SET CDROM=%%%%I:>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo if "%%CDROM%%"=="" goto end>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
:skipSetupCompleteCMD

if "%IncludeNET4%"=="0" goto skipNET4setup
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding NET Framework 4.8 to ISO/DVD....
 ECHO ================================================================
 ECHO.
 ECHO.
 copy /b /y "%~dp0hotfixes\ndp48-x86-x64-allos-enu.exe" "%~dp0DVD\Updates" >nul 2>&1
 copy /b /y "%~dp0hotfixes\ndp48-kb5001843-%ImageArchitecture%.exe" "%~dp0DVD\Updates" >nul 2>&1
 echo echo Installing NET Framework 4.8...>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo start /w "" "%%CDROM%%\Updates\ndp48-x86-x64-allos-enu.exe" /q /norestart>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 if not "%Net4LangPackFile%"=="" (
  copy /b /y "%~dp0hotfixes\%Net4LangPackFile%" "%~dp0DVD\Updates" >nul 2>&1
  echo echo Installing NET Framework Language Pack...>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
  echo start /w "" "%%CDROM%%\Updates\%Net4LangPackFile%" /q /norestart>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 )
 copy /b /y "%~dp0hotfixes\msiesu32.dll" "%~dp0DVD\Updates" >nul 2>&1
 if "%ImageArchitecture%"=="x64" copy /b /y "%~dp0hotfixes\msiesu64.dll" "%~dp0DVD\Updates" >nul 2>&1
 echo echo Installing NET Framework Rollup Update...>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 if "%ImageArchitecture%"=="x86" (
  echo copy /b /y "%%CDROM%%\Updates\msiesu32.dll" "%%SystemRoot%%\System32\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 )
 if "%ImageArchitecture%"=="x64" (
  echo copy /b /y "%%CDROM%%\Updates\msiesu32.dll" "%%SystemRoot%%\SysWOW64\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
  echo copy /b /y "%%CDROM%%\Updates\msiesu64.dll" "%%SystemRoot%%\System32\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 )
 echo reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msiexec.exe" /f ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msiexec.exe" /v VerifierDlls /t REG_SZ /d msiesu.dll /f ^>nul>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msiexec.exe" /v GlobalFlag /t REG_DWORD /d 256 /f ^>nul>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo net stop msiserver ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo start /w "" "%%CDROM%%\Updates\ndp48-kb5001843-%ImageArchitecture%.exe" /q /norestart>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msiexec.exe" /f ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 if "%ImageArchitecture%"=="x86" (
  echo del /q /f "%%SystemRoot%%\System32\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 )
 if "%ImageArchitecture%"=="x64" (
  echo del /q /f "%%SystemRoot%%\SysWOW64\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
  echo del /q /f "%%SystemRoot%%\System32\msiesu.dll" ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 )
 echo net stop msiserver ^>nul 2^>^&^1>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"

if "%ExecuteNGEN%"=="0" goto skipNGEN
 echo echo Executing Queued NET Compilations...>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo if not exist "%%windir%%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto noNET20x86>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo "%%windir%%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo :noNET20x86>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo if not exist "%%windir%%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" goto noNET20x64>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo "%%windir%%\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo :noNET20x64>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo if not exist "%%windir%%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" goto noNET40x86>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo "%%windir%%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo :noNET40x86>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo if not exist "%%windir%%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" goto noNET40x64>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo "%%windir%%\Microsoft.NET\Framework64\v4.0.30319\ngen.exe" executeQueuedItems ^>NUL 2^>NUL>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo :noNET40x64>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
:skipNGEN

 ECHO.
 ECHO Done.
 ECHO.
:skipNET4setup

if "%IncludeDX9%"=="0" goto skipDX9setup
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding DirectX 9 June 2010 to ISO/DVD....
 ECHO ================================================================
 ECHO.
 ECHO.
 start /w "" "%~dp0hotfixes\directx_Jun2010_redist.exe" /t:"%~dp0DVD\Updates\DX9" /c /q
 echo echo Installing DirectX 9 June 2010...>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo start /w "" "%%CDROM%%\Updates\DX9\DXSETUP.exe" /silent>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
:skipDX9setup


if not "%SetupCompleteCMD%"=="1" goto skipSetupCompleteCMD2
 echo :end>>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
 echo rd /S /Q "%%WINDIR%%\Setup\Scripts">>"%~dp0DVD\sources\$oem$\$$\Setup\Scripts\SetupComplete.cmd"
:skipSetupCompleteCMD2


ECHO.
ECHO.
ECHO ================================================================
ECHO Unpacking hotfixes...
ECHO ================================================================
ECHO.

rd /s/q "%~dp0hotfixes\unpacked" >NUL 2>&1
mkdir "%~dp0hotfixes\unpacked" >NUL 2>&1

mkdir "%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%" >NUL 2>&1
start /w "" "%~dp0hotfixes\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%.exe" /x:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%"

REM KB2533552 old servicing stack
mkdir "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%" >NUL 2>&1
expand "%~dp0hotfixes\Windows6.1-KB2533552-%ImageArchitecture%.msu" -F:* "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%" >NUL
mkdir "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab" >NUL 2>&1
expand "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\Windows6.1-KB2533552-%ImageArchitecture%.cab" -F:* "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab" >NUL
copy /b/y "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab\update.mum" "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab\update.mum.bak" >NUL 2>&1
findstr /i /v exclusive "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab\update.mum.bak" > "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab\update.mum"

ECHO.
ECHO Done.
ECHO.


for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 
ECHO.
ECHO.
ECHO ================================================================
ECHO Addding packages to image with index %%i
ECHO ================================================================
ECHO.

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2533552 - old update for Servicing Stack...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab"
REM Restore original update.mum for KB2533552....
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b/y "%~dp0hotfixes\unpacked\Windows6.1-KB2533552-%ImageArchitecture%\cab\update.mum.bak" "%~dp0mount\%%i\Windows\servicing\Packages\Package_for_KB2533552~31bf3856ad364e35~%PackagesArchitecture%~~6.1.1.1.mum""

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB4490628 - Servicing Stack 03/2019...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB4490628-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB4474419 - SHA-2 code signing support...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4474419-v3-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB4592510 - Servicing Stack 12/2020...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4592510-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding CPU Microcode Updates
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2818604-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3064209-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB3172605 - Quality Update Rollup 07/2016
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3172605-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB3179573 - Quality Update Rollup 08/2016
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3179573-%ImageArchitecture%.msu"


ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB3125574 - Convenience Rollup Update 05/2016...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb3125574-v4-%ImageArchitecture%.msu"

ECHO.
ECHO ================================================================
ECHO Adding Internet Explorer 11 pre-requisites...
ECHO ================================================================
ECHO.


ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2729094 - Segoe UI symbol font...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2729094-v2-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2533623 - API update...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2533623-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2670838 - Platform Update...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2670838-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding Internet Explorer 11...
ECHO ================================================================
ECHO.
ECHO.
ECHO ================================================================
ECHO Adding IE11 - main package...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Win7.CAB"
ECHO.
ECHO ================================================================
ECHO Adding IE11 - english spellcheck...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Spelling-en.MSU"
ECHO.
ECHO.
ECHO ================================================================
ECHO Adding IE11 - english hyphenation...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Hyphenation-en.MSU"
ECHO.
ECHO.

if exist "%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\ielangpack-%ImageLanguage%.CAB" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding IE11 - additional language pack: %ImageLanguage%...
 ECHO ================================================================
 ECHO.
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\ielangpack-%ImageLanguage%.CAB"
)

if exist "%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Spelling-%ImageLanguage%.MSU" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding IE11 - additional spellcheck: %ImageLanguage%...
 ECHO ================================================================
 ECHO.
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Spelling-%ImageLanguage%.MSU"
)

if exist "%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Hyphenation-%ImageLanguage%.MSU" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding IE11 - additional hyphenetion: %ImageLanguage%...
 ECHO ================================================================
 ECHO.
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\unpacked\IE11-Windows6.1-%ImageArchitecture%-%ImageLanguage%\IE-Hyphenation-%ImageLanguage%.MSU"
)


ECHO.
ECHO.
ECHO ================================================================
ECHO Adding Recommended Updates...
ECHO ================================================================
ECHO.
ECHO.
ECHO ================================================================
ECHO Adding KB917607 - Windows Help program
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB917607-%ImageArchitecture%.msu"
ECHO.
ECHO ================================================================
ECHO Adding KB2685813 - Kernel Mode Driver Framework Update
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb2685811-%ImageArchitecture%.msu"
ECHO.
ECHO ================================================================
ECHO Adding KB2685813 - User Mode Driver Framework Update...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Umdf-1.11-Win-6.1-%ImageArchitecture%.msu"
ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2547666 - IE11 long URL parsing fix...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2547666-%ImageArchitecture%.msu"
ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2545698 - Blured text in IE fix...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2545698-%ImageArchitecture%.msu"

if "%ImageArchitecture%"=="x64" (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Adding package KB2603229 - registry mismatch fix for x64 systems...
 ECHO ================================================================
 ECHO.
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2603229-x64.msu"
)

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2732059 - OXPS to XPS converter
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2732059-v5-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2750841 - IPv6 readiness update
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2750841-%ImageArchitecture%.msu"

ECHO.
ECHO ================================================================
ECHO Adding package KB2761217 - Calibri Light font
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2761217-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2773072 - Games Clasification Update
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2773072-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2834140 - Fix for Platform Update KB2670838 patch...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2834140-v2-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding RDP 8.0 server and 8.1 client
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2574819-v2-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2592687-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2830477-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2857650-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2913751-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2919469 - Canada Country Code Fix
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2919469-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding packages with updated Currencies Symbols
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2970228-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3006137-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3102429-v2-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Removing Windows Journal Application - potential security hole
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3161102-%ImageArchitecture%.msu"



ECHO.
ECHO.
ECHO ================================================================
ECHO Adding security hotfixes that are missing in cumulative updates...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2667402-v2-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2813347-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2984972-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2698365-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2862330-v2-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2900986-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2912390-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3046269-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3035126-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3031432-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3004375-v3-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3110329-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3161949-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3159398-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3156016-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3150220-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3059317-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding RDP 8.1 hotfixes
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2923545-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2984976-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3020388-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3075226-%ImageArchitecture%.msu"


ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB3138612 - Windows Update Client...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3138612-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding Internet Explorer 11 Cumulative Updates...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\ie11-windows6.1-kb3185319-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\ie11-windows6.1-kb4483187-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB2894844 - .NET 3.5.1 Security Update...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB2894844-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB4019990 - .NET 4.7 Pre-requsite...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4019990-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Applying ESU Updates eligibility...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\%EsuCom%.manifest" "%~dp0mount\%%i\Windows\WinSxS\Manifests""

reg load HKLM\TK_COMPONENTS "%~dp0mount\%%i\Windows\System32\config\COMPONENTS" >nul
reg delete "HKLM\TK_COMPONENTS\DerivedData\Components\%EsuCom%" /f >nul 2>&1
reg add "HKLM\TK_COMPONENTS\DerivedData\Components\%EsuCom%" /v "c^!%EsuFnd%" /t REG_BINARY /d "" /f >nul
reg add "HKLM\TK_COMPONENTS\DerivedData\Components\%EsuCom%" /v "identity" /t REG_BINARY /d "%EsuIdn%" /f >nul
reg add "HKLM\TK_COMPONENTS\DerivedData\Components\%EsuCom%" /v "S256H" /t REG_BINARY /d "%EsuHsh%" /f >nul
for /f "tokens=* delims=" %%# in ('reg query HKLM\TK_COMPONENTS\DerivedData\VersionedIndex 2^>nul ^| findstr /i VersionedIndex') do reg delete "%%#" /f
reg unload HKLM\TK_COMPONENTS >nul

reg load HKLM\TK_SOFTWARE "%~dp0mount\%%i\Windows\System32\config\SOFTWARE" >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Winners\%EsuKey%" /ve /d 6.1 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Winners\%EsuKey%\6.1" /ve /d 6.1.7603.25000 /f >nul
reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Winners\%EsuKey%\6.1" /v 6.1.7603.25000 /t REG_BINARY /d 01 /f >nul
reg unload HKLM\TK_SOFTWARE >nul

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding .NET 3.5.1 January 2020 Cumulative Updates...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4040980-%ImageArchitecture%.msu"
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4532945-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB4578952 - .NET 3.5.1 November 2020 Cumulative...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb4578952-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package KB5003233 - May 2021 Cumulative...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\windows6.1-kb5003233-%ImageArchitecture%.msu"

ECHO.
ECHO.
ECHO ================================================================
ECHO Adding package Universal C Runtime...
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-KB3118401-%ImageArchitecture%.msu"


)

REM Clean temporary unpacked
rd /s/q "%~dp0hotfixes\unpacked" >NUL 2>&1

:skipHotfixes

if not "%ApplyCustPatches%"=="1" goto skipCustPatches

setlocal ENABLEDELAYEDEXPANSION
set "PFx86=Program Files (x86)"

for /L %%i in (%ImageStart%, 1, %ImageCount%) do (

 echo.
 echo.
 ECHO ================================================================
 echo Mounting registry of image %%i
 ECHO ================================================================
 echo.

 reg load HKLM\TK_DEFAULT "%~dp0mount\%%i\Windows\System32\config\default" >nul
 reg load HKLM\TK_NTUSER "%~dp0mount\%%i\Users\Default\ntuser.dat" >nul
 reg load HKLM\TK_SOFTWARE "%~dp0mount\%%i\Windows\System32\config\SOFTWARE" >nul
 reg load HKLM\TK_SYSTEM "%~dp0mount\%%i\Windows\System32\config\SYSTEM" >nul

 ECHO.
 ECHO.
 ECHO ================================================================
 echo Applying custom fixes to image %%i
 ECHO ================================================================
 ECHO.

 REM Remove legacy VGA video driver
 if not "%RemoveLegacyVGA%"=="0" (

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\System32\DriverStore\display.inf_loc""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\vga.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\framebuf.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\drivers\vga.sys""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\drivers\vgapnp.sys""

  if "%ImageArchitecture%"=="x86" (
   "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s /q "%~dp0mount\%%i\Windows\System32\DriverStore\FileRepository\display.inf_x86_neutral_36353e26d7770ebb""
  )

  if "%ImageArchitecture%"=="x64" (
   "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s /q "%~dp0mount\%%i\Windows\System32\DriverStore\FileRepository\display.inf_amd64_neutral_ea1c8215e52777a6""
  )

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\VgaSave" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\VgaSave" /f
  del /q /f "%~dp0mount\%%i\Windows\inf\display.inf" >nul 2>&1
  del /q /f "%~dp0mount\%%i\Windows\inf\display.PNF" >nul 2>&1
  Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\Vga" /f >nul 2>&1
  Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\Vga" /f >nul 2>&1

 )

 REM Set default NTP time server
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /ve /t REG_SZ /d "0" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "0" /t REG_SZ /d "%NTPserver%" /f >nul
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "1" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "2" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "3" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "4" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers" /v "5" /f >nul 2>&1
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time" /v "Start" /t REG_DWORD /d "2" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\Parameters" /v "NtpServer" /t REG_SZ /d "%NTPserver%,0x9" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\Parameters" /v "Type" /t REG_SZ /d "NTP" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time" /v "Start" /t REG_DWORD /d "2" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time\Parameters" /v "NtpServer" /t REG_SZ /d "%NTPserver%,0x9" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time\Parameters" /v "Type" /t REG_SZ /d "NTP" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollInterval" /t REG_DWORD /d 86400 /f >nul
 reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollTimeRemaining" /f >nul 2>&1
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time\TimeProviders\NtpClient" /v "Enabled" /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollInterval" /t REG_DWORD /d 86400 /f >nul
 reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\W32Time\TimeProviders\NtpClient" /v "SpecialPollTimeRemaining" /f >nul 2>&1

 REM Disable Internet Connection Checking
 if not "%DisableInternetConnectionChecking%"=="0" (
  Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d 0 /f >nul
  Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\NlaSvc\Parameters\Internet" /v "EnableActiveProbing" /t REG_DWORD /d 0 /f >nul
 )

 REM Disable IP source rouring for security
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\Tcpip\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\Tcpip\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\Tcpip6\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\Tcpip6\Parameters" /v "DisableIPSourceRouting" /t REG_DWORD /d "2" /f >nul

 REM Disable End Of Support Notification
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\EOSNotify" /v "DiscontinueEOS" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\SipNotify" /v "DontRemindMe" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Gwx" /v "DisableGwx" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /t REG_DWORD /d 1 /f >nul

 REM Disable Action Center
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HideSCAHealth" /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\wscsvc" /v "Start" /t REG_DWORD /d "4" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\wscsvc" /v "Start" /t REG_DWORD /d "4" /f >nul

 REM Disable Windows Anytime Upgrade
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{BE122A0E-4503-11DA-8BDE-F66BAD1E3F3A}" /f >nul 2>&1
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\WAU" /v "Disabled" /t REG_DWORD /d 1 /f >nul
 del /q /f "%~dp0mount\1\ProgramData\Microsoft\Windows\Start Menu\Programs\Windows Anytime Upgrade.lnk" >nul 2>&1

 REM Disable User Account Control
 if not "%DisableUAC%"=="0" (
  reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA  /t REG_DWORD /d 0 /f >nul
 )

 REM Remove Windows Defender and MRT
 if not "%RemoveDefender%"=="0" (
  Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
  Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows Defender\Real-time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul
  Reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MRT" /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f >nul

  Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\WinDefend" /f >nul 2>&1
  Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\WinDefend" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\SafeBoot\Minimal\WinDefend" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\SafeBoot\Network\WinDefend" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\SafeBoot\Minimal\WinDefend" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\SafeBoot\Network\WinDefend" /f >nul 2>&1

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows Defender\MP Scheduled Scan" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows Defender\MpIdleTask" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{A1D60D55-A6B8-401B-BC05-2938E02DF2F2}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{A1D60D55-A6B8-401B-BC05-2938E02DF2F2}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{C4E8B14A-4159-4C58-BDAD-281DBBFC97E8}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{C4E8B14A-4159-4C58-BDAD-281DBBFC97E8}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows Defender" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows Defender" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{D8559EB9-20C0-410E-BEDA-7ED416AECC2A}" /f
  del /q/f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows Defender\*" >nul 2>&1
  rd /s/q "%~dp0mount\%%i\ProgramData\Microsoft\Windows Defender" >nul 2>&1
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s/q "%~dp0mount\%%i\Program Files\Windows Defender""
  if exist "%~dp0mount\%%i\!PFx86!\Windows Defender\*" "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s/q "%~dp0mount\%%i\!PFx86!\Windows Defender""

  reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v ScanWithAntiVirus /t REG_DWORD /d 1 /f >nul

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\APPID\{A79DB36D-6218-48e6-9EC9-DCBA9A39BF0F}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\APPID\{A79DB36D-6218-48e6-9EC9-DCBA9A39BF0F}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\APPID\{A79DB36D-6218-48e6-9EC9-DCBA9A39BF0F}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{2781761E-28E0-4109-99FE-B9D127C57AFE}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{2781761E-28E0-4109-99FE-B9D127C57AFE}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{2781761E-28E0-4109-99FE-B9D127C57AFE}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{A2D75874-6750-4931-94C1-C99D3BC9D0C7}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{D8559EB9-20C0-410E-BEDA-7ED416AECC2A}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{AC30C2BA-0109-403D-9D8E-140BB470379C}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{CDFED399-7999-4309-B064-1EDE04BC580D}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{E2D74550-8E41-460E-BB51-52E1F9522134}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\TypeLib\{8C389764-F036-48F2-9AE2-88C260DCF43B}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\TypeLib\{8C389764-F036-48F2-9AE2-88C260DCF43B}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\TypeLib\{8C389764-F036-48F2-9AE2-88C260DCF43B}" /f

  reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" /v "WindowsDefender-In" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" /v "WindowsDefender-Out" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" /v "WindowsDefender-In" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\Static\System" /v "WindowsDefender-Out" /f >nul 2>&1

  reg delete "HKEY_LOCAL_MACHINE\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Windows Defender/Operational" /f >nul 2>&1
  reg delete "HKEY_LOCAL_MACHINE\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Windows Defender/WHC" /f >nul 2>&1
  reg delete "HKEY_LOCAL_MACHINE\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{11cd958a-c507-4ef3-b3f2-5fd9dfbd2c78}" /f >nul 2>&1
  reg delete "HKEY_LOCAL_MACHINE\TK_SYSTEM\ControlSet001\services\eventlog\System\WinDefend" /f >nul 2>&1
  reg delete "HKEY_LOCAL_MACHINE\TK_SYSTEM\ControlSet002\services\eventlog\System\WinDefend" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger\EventLog-System\{11cd958a-c507-4ef3-b3f2-5fd9dfbd2c78}" /f >nul 2>&1
  reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\Autologger\EventLog-System\{11cd958a-c507-4ef3-b3f2-5fd9dfbd2c78}" /f >nul 2>&1

  type "%~dp0mount\%%i\Windows\winsxs\pending.xml" | find /i /v "-Malware" > "%~dp0hotfixes\pending.tmp"
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\pending.tmp" "%~dp0mount\%%i\Windows\winsxs\pending.xml""
 )

 REM Disable App Compatinility Assistant
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisablePCA" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\PcaSvc" /v "Start" /t REG_DWORD /d "4" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\PcaSvc" /v "Start" /t REG_DWORD /d "4" /f >nul

 
 REM Disable and Remove Telemetry and Spying
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "DontSendAdditionalData" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\MRT" /v "DontReportInfectionInformation" /t REG_DWORD /d 1 /f >nul

 Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\DiagTrack" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\DiagTrack" /f >nul 2>&1
 Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\IEEtwCollectorService" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\IEEtwCollectorService" /f >nul 2>&1

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance\BootCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Diagnostics\Performance\ShutdownCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Diagnostics\Performance" /v "DisableDiagnosticTracing" /t REG_DWORD /d "1" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Diagnostics\Performance\BootCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Diagnostics\Performance\ShutdownCKCLSettings" /v "Start" /t REG_DWORD /d "0" /f
 
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "4" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\DPS" /v "Start" /t REG_DWORD /d "4" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "4" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\DPS" /v "Start" /t REG_DWORD /d "4" /f

 Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Compat-Appraiser/Analytic" /f >nul 2>&1
 Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-Compat-Appraiser/Operational" /f >nul 2>&1
 Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{442c11c5-304b-45a4-ae73-dc2194c4e876}" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger\EventLog-Application\{442c11c5-304b-45a4-ae73-dc2194c4e876}" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\Autologger\EventLog-Application\{442c11c5-304b-45a4-ae73-dc2194c4e876}" /f >nul 2>&1

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\UpgradeExperienceIndicators" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\OneSettings" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" /f

 del /q /f "%~dp0mount\%%i\Windows\Migration\WTR\CompatTelemetry.inf" >nul 2>&1
 rd /s /q "%~dp0mount\%%i\Windows\AppCompat" >nul 2>&1

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\CompatTelRunner.exe""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\aitstatic.exe""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\appraiser.dll""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\devinv.dll""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\diagtrack.dll""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\acmigration.dll""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\invagent.dll""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\generaltel.dll""

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s /q "%~dp0mount\%%i\Windows\System32\CompatTel""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s /q "%~dp0mount\%%i\Windows\System32\appraiser""
 
 type "%~dp0mount\%%i\Windows\winsxs\pending.xml" | find /i /v "-Telemetry" | find /i /v "-Inventory" | find /i /v "-Appraiser" > "%~dp0hotfixes\pending.tmp"
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\pending.tmp" "%~dp0mount\%%i\Windows\winsxs\pending.xml""

 Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v DontRetryOnError /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v IsCensusDisabled /t REG_DWORD /d 1 /f >nul
 Reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\ClientTelemetry" /v TaskEnableRun /t REG_DWORD /d 1 /f >nul

 reg add "HKLM\TK_SOFTWARE\Microsoft\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > NUL
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > NUL
 reg add "HKLM\TK_NTUSER\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > NUL
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f > NUL

 REM Remove End of Support Notification
 type "%~dp0mount\%%i\Windows\winsxs\pending.xml" | find /i /v "-EOSNotify" > "%~dp0hotfixes\pending.tmp"
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\pending.tmp" "%~dp0mount\%%i\Windows\winsxs\pending.xml""
 
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\Migration\WTR\EOSNotifyMig.inf""
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\EOSNotify.exe""

 REM Remove telemetry Tasks
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Application Experience\AitAgent" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Application Experience\ProgramDataUpdater" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program\OptinNotification" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Maintenance\WinSAT" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\Diagnosis\Scheduled" >nul 2>&1
 del /q /f "%~dp0mount\1\Windows\System32\Tasks\Microsoft\Windows\PerfTrack\BackgroundConfigSurveyor" >nul 2>&1

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\AitAgent" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Application Experience\ProgramDataUpdater" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Customer Experience Improvement Program\OptinNotification" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Maintenance\WinSAT" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Diagnosis\Scheduled" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\PerfTrack\BackgroundConfigSurveyor" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{A7C73732-9F11-4281-8D19-764D4EC9D94D}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{A7C73732-9F11-4281-8D19-764D4EC9D94D}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{AC4E5ACF-89F7-4220-BA21-81EE183975E2}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{AC4E5ACF-89F7-4220-BA21-81EE183975E2}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{47536D45-EEEC-4BDC-8183-A4DC1F8DA9E4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{47536D45-EEEC-4BDC-8183-A4DC1F8DA9E4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{FDD56C73-F0D5-41B6-B767-6EFFD7966428}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FDD56C73-F0D5-41B6-B767-6EFFD7966428}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{C016366B-7126-46CA-B36B-592A3D95A60B}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{C016366B-7126-46CA-B36B-592A3D95A60B}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{DA41DE71-8431-42FB-9DB0-EB64A961DEAD}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{DA41DE71-8431-42FB-9DB0-EB64A961DEAD}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{BE669C13-8165-4536-96D0-6D6C39292AAE}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{BE669C13-8165-4536-96D0-6D6C39292AAE}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{B0CBAB43-44FC-469B-A4CE-87426761FDCE}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{B0CBAB43-44FC-469B-A4CE-87426761FDCE}" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Windows Error Reporting\QueueReporting" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Logon\{D0250F3F-6480-484F-B719-42F659AC64D5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{D0250F3F-6480-484F-B719-42F659AC64D5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Windows Error Reporting\QueueReporting" /f

 REM Remove Search Indexer
 Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\WSearch" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\WSearch" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet001\Services\WSearchIdxPi" /f >nul 2>&1
 Reg delete "HKLM\TK_SYSTEM\ControlSet002\Services\WSearchIdxPi" /f >nul 2>&1
 reg add "HKLM\TK_NTUSER\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\InfoBarsDisabled" /v "ServerMSSNotInstalled" /t REG_DWORD /d 1 /f >nul

 REM Remove System Restore
 if not "%RemoveSR%"=="0" (
  reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableSR" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore" /v "DisableConfig" /t REG_DWORD /d 1 /f >nul

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{0D41EBA2-17EA-4B0D-9172-DBD2AE0CC97A}" /f 
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{0D41EBA2-17EA-4B0D-9172-DBD2AE0CC97A}" /f 
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{0D41EBA2-17EA-4B0D-9172-DBD2AE0CC97A}" /f 
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{883FF1FC-09E1-48e5-8E54-E2469ACB0CFD}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{883FF1FC-09E1-48e5-8E54-E2469ACB0CFD}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{883FF1FC-09E1-48e5-8E54-E2469ACB0CFD}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{a47401f6-a8a6-40ea-9c29-b8f6026c98b8}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\SrControl.SrControl" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\SrControl.SrControl.1" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\SrDrvWuHelper.SrDrvWuHelper" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\SrDrvWuHelper.SrDrvWuHelper.1" /f

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\PolicyDefinitions\SystemRestore.admx""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\System32\rstrui.exe.mui""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\System32\srcore.dll.mui""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\System32\srrstr.dll.mui""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\rstrui.exe""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srclient.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srcore.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srdelayed.exe""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srhelper.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srrstr.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\srwmi.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\System32\wbem\sr.mof""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\sysWOW64\rstrui.exe.mui""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f /s "%~dp0mount\%%i\Windows\sysWOW64\srcore.dll.mui""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\sysWOW64\srclient.dll""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\sysWOW64\srdelayed.exe""
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "del /q /f "%~dp0mount\%%i\Windows\sysWOW64\srhelper.dll""

  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\App Management\WindowsFeatureCategories" /v "COMMONSTART/Programs/Accessories/System Tools/System Restore.lnk" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\App Management\WindowsFeatureCategories" /v "COMMONSTART/Programs/Accessories/System Tools/System Restore.lnk" /f

  del /q /f "%~dp0mount\%%i\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\System Tools\System Restore.lnk" >nul 2>&1
  del /q /f /s "%~dp0mount\%%i\Windows\System32\wbem\sr.mfl" >nul 2>&1
  del /q /f /s "%~dp0mount\%%i\Windows\PolicyDefinitions\SystemRestore.adml" >nul 2>&1

  del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\SystemRestore\SR" >nul 2>&1
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Boot\{994C86AD-A929-4B2C-88A0-4E25A107A029}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{994C86AD-A929-4B2C-88A0-4E25A107A029}" /f
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\SystemRestore\SR" /f
 
  type "%~dp0mount\%%i\Windows\winsxs\pending.xml" | find /i /v "-SystemRestore" > "%~dp0hotfixes\pending.tmp"
  "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\pending.tmp" "%~dp0mount\%%i\Windows\winsxs\pending.xml""
 )


 REM Remove unnecessary tasks

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Autochk\Proxy" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Boot\{D7B6E81D-3CF4-432C-84D2-24213F4316E6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{D7B6E81D-3CF4-432C-84D2-24213F4316E6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Autochk" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Defrag\ScheduledDefrag" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{5C0AEEEA-C154-45BE-8499-BEA5F11BAFF6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{5C0AEEEA-C154-45BE-8499-BEA5F11BAFF6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Defrag\ScheduledDefrag" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" >nul 2>&1

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\ActivateWindowsSearch" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\ConfigureInternetTimeService" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\DispatchRecoveryTasks" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\ehDRMInit" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\InstallPlayReady" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\mcupdate" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\MediaCenterRecoveryTask" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\ObjectStoreRecoveryTask" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\OCURActivate" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\OCURDiscovery" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PBDADiscovery" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PBDADiscoveryW1" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PBDADiscoveryW2" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PeriodicScanRetry" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PvrRecoveryTask" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\PvrScheduleTask" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\RecordingRestart" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\RegisterSearch" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\ReindexSearchRoot" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\SqlLiteRecoveryTask" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Media Center\UpdateRecordPath" >nul 2>&1

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\MemoryDiagnostic\CorruptionDetector" >nul 2>&1
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\MemoryDiagnostic\DecompressionFailureDetector" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{CEE64558-E1A7-4D9D-80A7-2001912BE5B5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{CEE64558-E1A7-4D9D-80A7-2001912BE5B5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{FA2BC0A6-8D4B-458A-85C8-2B8C72487513}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FA2BC0A6-8D4B-458A-85C8-2B8C72487513}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\MemoryDiagnostic\CorruptionDetector" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\MemoryDiagnostic\DecompressionFailureDetector" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\NetTrace\GatherNetworkInfo" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{81540B9F-B5BF-47EB-9C95-BE195BF2C664}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{81540B9F-B5BF-47EB-9C95-BE195BF2C664}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\NetTrace\GatherNetworkInfo" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{FB3C354D-297A-4EB2-9B58-090F6361906B}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FB3C354D-297A-4EB2-9B58-090F6361906B}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\RAC\RacTask" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{EACA24FF-236C-401D-A1E7-B3D5267B8A50}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{EACA24FF-236C-401D-A1E7-B3D5267B8A50}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\RAC\RacTask" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Registry\RegIdleBackup" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{CA4B8FF2-A4D2-4D88-A52E-3A5BDAF7F56E}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{CA4B8FF2-A4D2-4D88-A52E-3A5BDAF7F56E}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Registry\RegIdleBackup" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{DD9F510C-95F4-499A-90C8-BAC5BC372FF4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{DD9F510C-95F4-499A-90C8-BAC5BC372FF4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\SoftwareProtectionPlatform\SvcRestartTask" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\Windows Media Sharing\UpdateLibrary" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{753C47AE-EC5E-44B3-95A9-2C8E553F0E39}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{753C47AE-EC5E-44B3-95A9-2C8E553F0E39}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\Windows Media Sharing" /f

 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\WindowsBackup\ConfigNotification" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{2F57269B-1E09-4E2D-AB1E-B0FDAC7D279C}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{2F57269B-1E09-4E2D-AB1E-B0FDAC7D279C}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\WindowsBackup\ConfigNotification" /f
 
 del /q /f "%~dp0mount\%%i\Windows\System32\Tasks\Microsoft\Windows\WDI\ResolutionHost" >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Plain\{9435F817-FED2-454E-88CD-7F78FDA62C48}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{9435F817-FED2-454E-88CD-7F78FDA62C48}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Microsoft\Windows\WDI\ResolutionHost" /f


 REM Remove telemetry Logs
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\SQMLogger" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E Reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\SQMLogger" /f
 reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener" /f >nul 2>&1
 reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener" /f >nul 2>&1


 REM Disable Event Logs
 if not "%DisableEventLogs%"=="0" (
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\EventLog-Application" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\EventLog-System" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\EventLog-Security" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\EventLog-Application" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\EventLog-System" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\EventLog-Security" /v "Start" /t REG_DWORD /d 0 /f >nul
 )


 REM Disable other Logs
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\AITEventLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\Audio" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\Circular Kernel Context Logger" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\DiagLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\Microsoft-Windows-Setup" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\NBSMBLOGGER" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\NtfsLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\PEAuthLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\RAC_PS" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\RdrLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\ReadyBoot" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\TCPIPLOGGER" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\Tpm" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\UBPM" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\WdiContextLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\AutoLogger\WFP-IPsec Trace" /v "Start" /t REG_DWORD /d 0 /f >nul

  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\AITEventLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\Audio" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\Circular Kernel Context Logger" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\DiagLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\Microsoft-Windows-Setup" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\NBSMBLOGGER" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\NtfsLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\PEAuthLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\RAC_PS" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\RdrLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\ReadyBoot" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\TCPIPLOGGER" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\Tpm" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\UBPM" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\WdiContextLog" /v "Start" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\AutoLogger\WFP-IPsec Trace" /v "Start" /t REG_DWORD /d 0 /f >nul

 
 REM Completely remove Action Center and Windows Security Center
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\AppID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\AppID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\AppID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{E9495B87-D950-4ab5-87A5-FF6D70BF3E90}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{49ACAA99-F009-4524-9D2A-D751C9A38F60}" /f


 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\TypeLib\{C2A2B169-4052-4037-88D9-E274AF31C6F7}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\TypeLib\{C2A2B169-4052-4037-88D9-E274AF31C6F7}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\TypeLib\{C2A2B169-4052-4037-88D9-E274AF31C6F7}" /f


 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\ControlPanel\NameSpace\{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\explorer\ControlPanel\NameSpace\{BB64F8A7-BEE7-4E1A-AB8D-7D8273F7FDB6}" /f


 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\AppID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\AppID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\AppID\{8D26D9AA-5DA8-4b95-949A-B74954A229A6}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{01afc156-f2eb-4c1c-a722-8550417d396f}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{014a1425-828b-482a-a386-5763b23531c3}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{0acabbb8-8f37-4605-9d41-eec1c33eeb95}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{0cc6fe25-a88b-480d-956a-a9a20bd2c65a}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{1cf5e433-3cf8-498e-8b5a-f47e23200e07}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{3d2eafc0-96d0-4925-9f7d-ff80b168f243}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{418ee892-56f0-4c3b-9238-696ba0cef799}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{58d879fe-5b40-46aa-ab68-d146ff6a68a0}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{7cbc33db-7a53-45c3-a0cc-610292bd7b9e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{8025d477-47d3-449c-9350-c676140ee829}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{824f0d64-069c-4383-9107-f18fc40c3ca6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{8db6ae56-7ea1-421c-9c22-d3247c12c6c4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{B066DDE3-445D-45dc-BF2A-BC7BAA74C5C5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{b387c51b-7fe4-4252-8cd4-585592b4dc7e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{db62c52c-dbae-476c-aeac-fa9966e85326}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{e90aad8b-7f0c-480d-b33e-16779c4cf59d}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Interface\{FAE9CE59-7621-4208-8BC3-2ACECD58FED2}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{014a1425-828b-482a-a386-5763b23531c3}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{0acabbb8-8f37-4605-9d41-eec1c33eeb95}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{0cc6fe25-a88b-480d-956a-a9a20bd2c65a}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{1cf5e433-3cf8-498e-8b5a-f47e23200e07}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{3d2eafc0-96d0-4925-9f7d-ff80b168f243}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{418ee892-56f0-4c3b-9238-696ba0cef799}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{58d879fe-5b40-46aa-ab68-d146ff6a68a0}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{7cbc33db-7a53-45c3-a0cc-610292bd7b9e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{8025d477-47d3-449c-9350-c676140ee829}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{824f0d64-069c-4383-9107-f18fc40c3ca6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{8db6ae56-7ea1-421c-9c22-d3247c12c6c4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{B066DDE3-445D-45dc-BF2A-BC7BAA74C5C5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{b387c51b-7fe4-4252-8cd4-585592b4dc7e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{db62c52c-dbae-476c-aeac-fa9966e85326}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{e90aad8b-7f0c-480d-b33e-16779c4cf59d}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\Interface\{FAE9CE59-7621-4208-8BC3-2ACECD58FED2}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{014a1425-828b-482a-a386-5763b23531c3}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{0acabbb8-8f37-4605-9d41-eec1c33eeb95}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{0cc6fe25-a88b-480d-956a-a9a20bd2c65a}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{1cf5e433-3cf8-498e-8b5a-f47e23200e07}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{3d2eafc0-96d0-4925-9f7d-ff80b168f243}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{418ee892-56f0-4c3b-9238-696ba0cef799}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{58d879fe-5b40-46aa-ab68-d146ff6a68a0}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{7cbc33db-7a53-45c3-a0cc-610292bd7b9e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{8025d477-47d3-449c-9350-c676140ee829}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{824f0d64-069c-4383-9107-f18fc40c3ca6}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{8db6ae56-7ea1-421c-9c22-d3247c12c6c4}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{B066DDE3-445D-45dc-BF2A-BC7BAA74C5C5}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{b387c51b-7fe4-4252-8cd4-585592b4dc7e}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{db62c52c-dbae-476c-aeac-fa9966e85326}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{e90aad8b-7f0c-480d-b33e-16779c4cf59d}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\Interface\{FAE9CE59-7621-4208-8BC3-2ACECD58FED2}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{a3b3c46c-05d8-429b-bf66-87068b4ce563}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{a3b3c46c-05d8-429b-bf66-87068b4ce563}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{a3b3c46c-05d8-429b-bf66-87068b4ce563}" /f


 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellServiceObjects\{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\explorer\ShellServiceObjects\{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{05F3561D-0358-4687-8ACD-A34D24C488DF}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{05F3561D-0358-4687-8ACD-A34D24C488DF}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{05F3561D-0358-4687-8ACD-A34D24C488DF}" /f

 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\CLSID\{2C673043-FC2E-4d67-8920-517D24DEBD2C}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Classes\Wow6432Node\CLSID\{2C673043-FC2E-4d67-8920-517D24DEBD2C}" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Classes\CLSID\{2C673043-FC2E-4d67-8920-517D24DEBD2C}" /f


 reg delete "HKLM\TK_SYSTEM\ControlSet001\services\wscsvc" /f >nul 2>&1
 reg delete "HKLM\TK_SYSTEM\ControlSet002\services\wscsvc" /f >nul 2>&1

 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{5857d6ca-9732-4454-809b-2a87b70881f8}" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-WSC-SRV/Diagnostic" /f >nul 2>&1

 reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WMI\Autologger\EventLog-System\{01979c6a-42fa-414c-b8aa-eee2c8202018}" /f >nul 2>&1
 reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WMI\Autologger\EventLog-System\{01979c6a-42fa-414c-b8aa-eee2c8202018}" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{01979c6a-42fa-414c-b8aa-eee2c8202018}" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-WindowsBackup/ActionCenter" /f >nul 2>&1

 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{588c5c5a-ffc5-44a2-9a7f-d5e8dbe6efd7}" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-HealthCenter/Debug" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-HealthCenter/Performance" /f >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WDI\Scenarios\{fd5aa730-b53f-4b39-84e5-cb4303621d74}\Instrumentation\{588c5c5a-ffc5-44a2-9a7f-d5e8dbe6efd7};*" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WDI\Scenarios\{fd5aa730-b53f-4b39-84e5-cb4303621d74}\Instrumentation\{588c5c5a-ffc5-44a2-9a7f-d5e8dbe6efd7};*" /f

 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Publishers\{959f1fac-7ca8-4ed1-89dc-cdfa7e093cb0}" /f >nul 2>&1
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WINEVT\Channels\Microsoft-Windows-HealthCenterCPL/Performance" /f >nul 2>&1
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SYSTEM\ControlSet001\Control\WDI\Scenarios\{fd5aa730-b53f-4b39-84e5-cb4303621d74}\Instrumentation\{959f1fac-7ca8-4ed1-89dc-cdfa7e093cb0};*" /f
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E reg delete "HKLM\TK_SYSTEM\ControlSet002\Control\WDI\Scenarios\{fd5aa730-b53f-4b39-84e5-cb4303621d74}\Instrumentation\{959f1fac-7ca8-4ed1-89dc-cdfa7e093cb0};*" /f

 type "%~dp0mount\%%i\Windows\winsxs\pending.xml" | find /i /v "-Securitycenter" > "%~dp0hotfixes\pending.tmp"
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "copy /b /y "%~dp0hotfixes\pending.tmp" "%~dp0mount\%%i\Windows\winsxs\pending.xml""


 REM Disable IPv6 Depricated Tunneling Services
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\TCPIP6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "1" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\TCPIP6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "1" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "4" /f >nul
 Reg add "HKLM\TK_SYSTEM\ControlSet002\Services\iphlpsvc" /v "Start" /t REG_DWORD /d "4" /f >nul

 REM Disable Meltdown and Spectre fixes
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul
 
 REM Disable AutoPlay for other drives than CD/DVD - for security
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HonorAutoRunSetting" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "HonorAutoRunSetting" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 223 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoDriveTypeAutoRun" /t REG_DWORD /d 223 /f >nul


 REM Show "My Computer" on Desktop
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f >nul


 REM Various system tweaks
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\OptimalLayout" /v "EnableAutoLayout" /t REG_DWORD /d 0 /f >nul

 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f >nul

 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\CrashControl" /v SendAlert /t REG_DWORD /d 0 /f >nul

 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\CrashControl" /v LogEvent /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\CrashControl" /v SendAlert /t REG_DWORD /d 0 /f >nul

 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager" /v AutoChkTimeOut /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Session Manager" /v AutoChkTimeOut /t REG_DWORD /d 1 /f >nul
 
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Environment" /v DEVMGR_SHOW_DETAILS /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet001\Control\Session Manager\Environment" /v DEVMGR_SHOW_NONPRESENT_DEVICES /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Session Manager\Environment" /v DEVMGR_SHOW_DETAILS /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Control\Session Manager\Environment" /v DEVMGR_SHOW_NONPRESENT_DEVICES /t REG_DWORD /d 1 /f >nul

 
 REM Tweaks to disable Autoshare Disks
 reg add "HKLM\TK_SYSTEM\ControlSet001\Services\lanmanserver\parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SYSTEM\ControlSet002\Services\lanmanserver\parameters" /v AutoShareWks /t REG_DWORD /d 0 /f >nul

 REM Disable UAC on Shared Foldes which sometimes causes problems
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f >nul

 REM IE11 Tweaks
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "about:blank" /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "https://www.google.com/" /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\Main" /v "SmoothScroll" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "WarnOnClose" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "OpenAllHomePages" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "Groups" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "NewTabPageShow" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Internet Explorer\TabbedBrowsing" /v "PopupsUseNewWindow" /t REG_DWORD /d 0 /f >nul

 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Main" /v "DisableFirstRunCustomize" /t REG_DWORD /d 1 /f >nul

 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "about:blank" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "https://www.google.com/" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default_Page_URL" /t REG_SZ /d "about:blank" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default_Search_URL" /t REG_SZ /d "https://www.google.com/" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\Main" /v "EnableAutoUpgrade" /t REG_DWORD /d 0 /f >nul


 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\PhishingFilter" /v "EnabledV9" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\Internet Explorer\Suggested Sites" /v "Enabled" /t REG_DWORD /d 0 /f >nul
 
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "SaveZoneInformation" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v "HideZoneInfoOnProperties" /t REG_DWORD /d 1 /f >nul

 REM Replace Bing with Google
 reg delete "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0633EE93-D776-472f-A0FF-E1416B8B2E3A}" /f >nul 2>&1

 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "DefaultScope" /t REG_SZ /d "{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "DownloadUpdates" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "Version" /t REG_DWORD /d 4 /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes" /v "ShowSearchSuggestionsInAddressGlobal" /t REG_DWORD /d 0 /f >nul

 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "DisplayName" /t REG_SZ /d "Google" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "URL" /t REG_SZ /d "https://www.google.com/search?q={searchTerms}" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "ShowSearchSuggestions" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "SuggestionsURL_JSON" /t REG_SZ /d "https://suggestqueries.google.com/complete/search?output=firefox&client=firefox&qu={searchTerms}" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Internet Explorer\SearchScopes\{0BBF48E6-FF9D-4FAA-AA4D-BDBB423B2BE1}" /v "FaviconURL" /t REG_SZ /d "https://www.google.com/favicon.ico" /f >nul

 REM Media Player Tweaks
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "AcceptedPrivacyStatement" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "UpgradeCheckFrequency" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "MediaLibraryCreateNewDatabase" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "MetadataRetrieval" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "SilentAcquisition" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "UsageTracking" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUMusic" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUPictures" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUVideo" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "DisableMRUPlaylists" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "FirstRun" /t REG_DWORD /d 0 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Microsoft\MediaPlayer\Preferences" /v "LaunchIndex" /t REG_DWORD /d 1 /f >nul

 REM Windows Media Player Privacy
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" /v "DisableAutoUpdate" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_SOFTWARE\Policies\Microsoft\WindowsMediaPlayer" /v "PreventLibrarySharing" /t REG_DWORD /d 1 /f >nul


 REM Re-enable SafeDisk Service for compatibility with old Games
 Reg add "HKLM\TK_SYSTEM\ControlSet001\Services\secdrv" /v Start /t REG_DWORD /d 2 /f >nul


 REM Enable Fraunhofer IIS MP3 Professional Codec

 if "%ImageArchitecture%"=="x64" (
  reg delete "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "D:\Windows\SysWOW64\l3codeca.acm" /f >nul 2>&1
  reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "D:\Windows\SysWOW64\l3codecp.acm" /t REG_SZ /d "Fraunhofer IIS MPEG Audio Layer-3 Codec (professional)" /f >nul
  reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\Drivers32" /v "msacm.l3acm" /t REG_SZ /d "D:\Windows\SysWOW64\l3codecp.acm" /f >nul
 )

 reg delete "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "D:\Windows\System32\l3codeca.acm" /f >nul 2>&1
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\drivers.desc" /v "D:\Windows\System32\l3codecp.acm" /t REG_SZ /d "Fraunhofer IIS MPEG Audio Layer-3 Codec (professional)" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows NT\CurrentVersion\Drivers32" /v "msacm.l3acm" /t REG_SZ /d "D:\Windows\System32\l3codecp.acm" /f >nul


 REM Disable obsolete SSL and TLS protocols
 if not "%DisableObsoleteSSL%"=="0" (
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet001\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "DisabledByDefault" /t REG_DWORD /d 1 /f >nul
  reg add "HKLM\TK_SYSTEM\ControlSet002\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client" /v "Enabled" /t REG_DWORD /d 0 /f >nul
  if "%ImageArchitecture%"=="x64" (
   reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v "DefaultSecureProtocols" /t REG_DWORD /d "2048" /f >nul
   reg add "HKLM\TK_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" /v "SecureProtocols" /t REG_DWORD /d "2048" /f >nul
  )
  reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" /v "DefaultSecureProtocols" /t REG_DWORD /d "2048" /f >nul
  reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v "SecureProtocols" /t REG_DWORD /d "2048" /f >nul
  reg add "HKLM\TK_NTUSER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "SecureProtocols" /t REG_DWORD /d "2048" /f >nul
 )


 REM Switch Windows Updates installation to Manual
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v "AUOptions" /t REG_DWORD /d 1 /f >nul
 
 REM Switch Windows Update to Microsoft Update
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending\7971f918-a847-4430-9279-4a52d1efe18d" /v "ClientApplicationID" /t REG_SZ /d "My App" /f >nul
 reg add "HKLM\TK_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending\7971f918-a847-4430-9279-4a52d1efe18d" /v "RegisterWithAU" /t REG_DWORD /d 1 /f >nul
 
 
 REM SysInternals Tools EULA Accepted

 reg add "HKLM\TK_NTUSER\Software\Sysinternals\AutoRuns" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\ClockRes" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Coreinfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Desktops" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Disk2Vhd" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\DiskExt" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\DiskView" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Du" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\FindLinks" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Handle" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Hex2Dec" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Junction" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\ListDLLs" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Movefile" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\NTFSInfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PendMove" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Process Explorer" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Process Monitor" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsExec" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsFile" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsGetSid" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsInfo" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsKill" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsList" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsLoggedon" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsLoglist" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsPasswd" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsPing" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsService" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsShutdown" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\PsSuspend" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\SDelete" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Share Enum" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Streams" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Strings" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Sync" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\TCPView" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\VolumeID" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul
 reg add "HKLM\TK_NTUSER\Software\Sysinternals\Whois" /v "EulaAccepted" /t REG_DWORD /d 1 /f >nul

 del /q /f "%~dp0hotfixes\pending.tmp" >nul 2>&1

 ECHO.
 ECHO Done
 ECHO.

 ECHO.
 ECHO.
 ECHO ================================================================
 echo Unmounting Registry of image %%i
 ECHO ================================================================
 ECHO.

 timeout /t 7 /NOBREAK >NUL

 reg unload HKLM\TK_DEFAULT >nul
 reg unload HKLM\TK_NTUSER >nul
 reg unload HKLM\TK_SOFTWARE >nul
 reg unload HKLM\TK_SYSTEM >nul

 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Copying files from add_these_files_to_Windows to Install.wim
 ECHO ================================================================
 ECHO.


 xcopy "%~dp0add_these_files_to_Windows\%ImageArchitecture%\*" "%~dp0mount\%%i\" /e/s/y >nul 2>&1

 ECHO.
 ECHO Done
 ECHO.

)



:skipCustPatches


if not "%Win10ImageArchitecture%"=="%ImageArchitecture%" goto skipWin10InstallerEFI

for /L %%i in (%ImageStart%, 1, %ImageCount%) do (
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "rd /s /q "%~dp0mount\%%i\Windows\Boot""
 timeout /t 6 /NOBREAK >NUL
 "%~dp0tools\%HostArchitecture%\NSudo.exe" -U:T -P:E cmd /c "xcopy "%~dp0Win10_Installer\EFI_Boot\*" "%~dp0mount\%%i\Windows\Boot\" /e /s /y"
 timeout /t 6 /NOBREAK >NUL
)

:skipWin10InstallerEFI


if not "%AddDrivers%"=="1" goto skipDrivers


cd /d "%~dp0hotfixes"
if "%ImageArchitecture%"=="x86" (
 if not exist "%~dp0hotfixes\windows6.1-kb2864202-x86.msu" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "windows6.1-kb2864202-x86.msu" "http://download.windowsupdate.com/d/msdownload/update/software/secu/2013/07/windows6.1-kb2864202-x86_9e556e48e72ae30ec89c5f1c713acde26da2556a.msu"
)
if "%ImageArchitecture%"=="x64" (
 if not exist "%~dp0hotfixes\windows6.1-kb2864202-x64.msu" "%~dp0tools\%HostArchitecture%\wget.exe" -q --show-progress --no-hsts --no-check-certificate -O "windows6.1-kb2864202-x64.msu" "http://download.windowsupdate.com/d/msdownload/update/software/secu/2013/07/windows6.1-kb2864202-x64_92617ad813adf4795cd694d828558271086f4f70.msu"
)
cd /d "%~dp0"


set BootDrivers=1
dir /a/s/b "%~dp0add_these_drivers_to_Installer\%ImageArchitecture%\*.inf" >nul 2>&1
if errorlevel 1 set BootDrivers=0
if "%Win10ImageArchitecture%"=="%ImageArchitecture%" set BootDrivers=0

set WinREDrivers=1
dir /a/s/b "%~dp0add_these_drivers_to_Recovery\%ImageArchitecture%\*.inf" >nul 2>&1
if errorlevel 1 set WinREDrivers=0

set InstallDrivers=1
dir /a/s/b "%~dp0add_these_drivers_to_Windows\%ImageArchitecture%\*.inf" >nul 2>&1
if errorlevel 1 set InstallDrivers=0


if not "%BootDrivers%"=="1" goto skipBootDrivers

 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Addding drivers to Installer (Boot.wim)
 ECHO ================================================================
 ECHO.


 mkdir "%~dp0mount\Boot" >nul 2>&1
 set BootCount=1
 for /f "tokens=2 delims=: " %%i in ('start "" /b "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /English /Get-WimInfo /WimFile:"%~dp0DVD\sources\boot.wim" ^| findstr /i Index') do (set BootCount=%%i)
 
 for /L %%i in (1, 1, %BootCount%) do (
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Mount-Wim /WimFile:"%~dp0DVD\sources\boot.wim" /index:%%i /MountDir:"%~dp0mount\Boot"
  REM Pre-requsite for USB3
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\Boot" /PackagePath:"%~dp0hotfixes\Windows6.1-kb2864202-%ImageArchitecture%.msu"
  REM Other drivers
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Image:"%~dp0mount\Boot" /Add-Driver /Driver:"%~dp0add_these_drivers_to_Installer\%ImageArchitecture%" /Recurse /ForceUnsigned
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Unmount-Wim /MountDir:"%~dp0mount\Boot" /commit
 )
 rd /s/q "%~dp0mount\Boot" >nul 2>&1


:skipBootDrivers


if not "%InstallDrivers%"=="1" goto skipDrivers


 for /L %%i in (%ImageStart%, 1, %ImageCount%) do (

  ECHO.
  ECHO.
  ECHO ================================================================
  ECHO Addding drivers to image %%i
  ECHO ================================================================
  ECHO.
  if exist "%~dp0hotfixes\NVMe\windows6.1-KB2990941-v3-%ImageArchitecture%.msu" (
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\NVMe\windows6.1-KB2990941-v3-%ImageArchitecture%.msu"
  )
  REM If rollup updates are not integrated, these pre-requisites are needed
  if "%InstallHotfixes%"=="0" (
   REM NVMe pre-requisite
   if exist "%~dp0hotfixes\NVMe\windows6.1-KB3087873-v2-%ImageArchitecture%.msu" (
    "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\NVMe\windows6.1-KB3087873-v2-%ImageArchitecture%.msu"
   )
   REM Pre-requisite for USB3
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\%%i" /PackagePath:"%~dp0hotfixes\Windows6.1-kb2864202-%ImageArchitecture%.msu"
  )
  "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Image:"%~dp0mount\%%i" /Add-Driver /Driver:"%~dp0add_these_drivers_to_Windows\%ImageArchitecture%" /Recurse /ForceUnsigned

  if "%WinREDrivers%"=="1" (
   ECHO.
   ECHO.
   ECHO ================================================================
   ECHO Addding drivers to recovery of image %%i
   ECHO ================================================================
   ECHO.
   mkdir "%~dp0mount\WinRE" >nul 2>&1
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Mount-Wim /WimFile:"%~dp0mount\%%i\Windows\System32\Recovery\winRE.wim" /index:1 /MountDir:"%~dp0mount\WinRE"
   REM Pre-requisite for USB3
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\WinRE" /PackagePath:"%~dp0hotfixes\Windows6.1-kb2864202-%ImageArchitecture%.msu"
   REM Generic NVMe drivers
   if exist "%~dp0hotfixes\NVMe\windows6.1-KB2990941-v3-%ImageArchitecture%.msu" (
    "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\WinRE" /PackagePath:"%~dp0hotfixes\NVMe\windows6.1-KB2990941-v3-%ImageArchitecture%.msu"
   )
   if exist "%~dp0hotfixes\NVMe\windows6.1-KB3087873-v2-%ImageArchitecture%.msu" (
    "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Add-Package /Image:"%~dp0mount\WinRE" /PackagePath:"%~dp0hotfixes\NVMe\windows6.1-KB3087873-v2-%ImageArchitecture%.msu"
   )
   REM Other drivers
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Image:"%~dp0mount\WinRE" /Add-Driver /Driver:"%~dp0add_these_drivers_to_Recovery\%ImageArchitecture%" /Recurse /ForceUnsigned
   "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Unmount-Wim /MountDir:"%~dp0mount\WinRE" /commit
  )
  

 )

 rd /s/q "%~dp0mount\WinRE" >nul 2>&1


:skipDrivers


if not "%CleanupImages%"=="1" goto skipCleanUp

for /L %%i in (%ImageStart%, 1, %ImageCount%) do (

 ECHO.
 ECHO.
 ECHO ================================================================
 echo Cleaning image %%i
 ECHO ================================================================
 ECHO.

 rem Commented out, because below line does not work on Windows 7
 rem "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Image:"%~dp0mount\%%i" /Cleanup-Image /StartComponentCleanup /ResetBase

 rem Below line is usefull only if you have manualy integrated Service Pack
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Image:"%~dp0mount\%%i" /Cleanup-Image /SPSuperseded /HideSP

)

:skipCleanUp

for /L %%i in (%ImageStart%, 1, %ImageCount%) do (

 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO Unounting image %%i of Install.wim
 ECHO ================================================================
 ECHO.
 "%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Unmount-Wim /MountDir:"%~dp0mount\%%i" /commit
 rd /s/q "%~dp0mount\%%i" >nul 2>&1

)


:skipMount


if not "%RepackImages%"=="1" goto skipRepack


if "%Win10ImageArchitecture%"=="%ImageArchitecture%" goto skipRepackBootWim
ECHO.
ECHO.
ECHO ================================================================
ECHO Repacking file boot.wim
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\imagex.exe" /export "%~dp0DVD\sources\boot.wim" "*" "%~dp0DVD\sources\boot_temp.wim" /CHECK /COMPRESS maximum
move /y "%~dp0DVD\sources\boot_temp.wim" "%~dp0DVD\sources\boot.wim" >NUL
:skipRepackBootWim

ECHO.
ECHO.
ECHO ================================================================
ECHO Repacking file install.wim
ECHO ================================================================
ECHO.
"%~dp0tools\%HostArchitecture%\DISM\imagex.exe" /export "%~dp0DVD\sources\install.wim" "*" "%~dp0DVD\sources\install_temp.wim" /CHECK /COMPRESS maximum
move /y "%~dp0DVD\sources\install_temp.wim" "%~dp0DVD\sources\install.wim" >NUL

:skipRepack


if not "%SplitInstallWim%"=="1" goto SkipSplitInstallWim

FOR /F "usebackq" %%A IN ('%~dp0DVD\sources\install.wim') DO set "InstallWimSize=%%~zA"
if "%InstallWimSize%" LSS "4294967296" goto SkipSplitInstallWim

ECHO.
ECHO.
ECHO ================================================================
ECHO Splitting file install.wim
ECHO ================================================================
ECHO.

"%~dp0tools\%HostArchitecture%\DISM\dism.exe" /Split-Image /ImageFile:"%~dp0DVD\sources\install.wim" /SWMFile:"%~dp0DVD\sources\install.swm" /FileSize:3700
del /q /f "%~dp0DVD\sources\install.wim" >nul 2>&1

:SkipSplitInstallWim


if "%CreateISO%"=="0" goto dontCreateISO

ECHO.
ECHO.
ECHO ================================================================
ECHO Creating new DVD image
ECHO ================================================================
ECHO.

 if "%ImageArchitecture%"=="x86" "%~dp0tools\%HostArchitecture%\oscdimg.exe" -b"%~dp0DVD\boot\etfsboot.com" -h -m -u2 -udfver102 "%~dp0DVD" "%~dp0Windows7_x86_%ImageLanguage%.iso" -lWin7

 if "%ImageArchitecture%"=="x64" "%~dp0tools\%HostArchitecture%\oscdimg.exe" -bootdata:2#p0,e,b"%~dp0DVD\boot\etfsboot.com"#pEF,e,b"%~dp0DVD\efi\microsoft\boot\Efisys.bin" -h -m -u2 -udfver102 "%~dp0DVD" "%~dp0Windows7_x64_%ImageLanguage%.iso" -lWin7

 REM Clean DVD directory
 rd /s /q "%~dp0DVD" >nul 2>&1
 mkdir "%~dp0DVD" >nul 2>&1

:dontCreateISO


ECHO.
ECHO.
ECHO.
ECHO All finished.
ECHO.
ECHO Press any key to end the script.
ECHO.
PAUSE >NUL


:end
