@echo off
TITLE Adobe Flash Player Installer
CLS

::
:: Author: Wojciech Keller
:: Version: 1.1a
:: License: free
::
:: for Windows XP/Vista/7 32-bit and 64-bit
::

:: ============================================================================================================
:: -------------- Start of Configuration Section --------------------------------------------------------------
:: ============================================================================================================

:: - Install latest Adobe Flash Player for Internet Explorer (ActiveX)
 set InstallFlashAX=1
:: - Install latest Adobe Flash Player for Firefox (NPAPI)
 set InstallFlashNP=1
:: - Install latest Adobe Flash Player for Opera (PPAPI)
 set InstallFlashPP=1

:: ============================================================================================================
:: ------------- End of Configuration Section -----------------------------------------------------------------
:: ============================================================================================================


:: ============================================================================================================


cd /d "%~dp0"

set WGET=wget

if exist "%~dp0wget.exe" (
 set WGET="%~dp0wget.exe"
 goto wgetFound
)

where wget >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
 ECHO.
 ECHO.
 ECHO ================================================================
 ECHO WGET tool not found!
 ECHO.
 ECHO Please download it: https://eternallybored.org/misc/wget/
 ECHO and put it into script directory.
 ECHO ================================================================
 ECHO.
 PAUSE >NUL
 goto end
)

:wgetFound 


set InstallFlash=0
if not "%InstallFlashAX%"=="0" set InstallFlash=1
if not "%InstallFlashNP%"=="0" set InstallFlash=1
if not "%InstallFlashPP%"=="0" set InstallFlash=1

if "%InstallFlash%"=="0" goto end

ECHO.
ECHO.
ECHO ================================================================
echo Detecting latest Adobe Flash Player version...
ECHO ================================================================
ECHO.
set FlashVersion=
for /f "tokens=1-3 delims=<>" %%i in ('wget --no-hsts --no-check-certificate -qO- "http://get.adobe.com/flashplayer/about/" ^| findstr /i /r /c:"<td>[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*</td>" 2^>nul') do (set "FlashVersion=%%k")

if not "%FlashVersion%"=="" (
 echo.
 echo.
 ECHO ================================================================
 echo Detected Flash Player version: %FlashVersion%
 ECHO ================================================================
 echo.
)

if "%FlashVersion%"=="" (
 echo.
 echo.
 ECHO ================================================================
 echo Unable to detect latest version of Adobe Flash Player.
 echo Skipping Flash Player instalation.
 ECHO ================================================================
 echo.
 goto errorFlashPlayer
)

cd /d "%TEMP%"

if not "%InstallFlashAX%"=="0" (

 echo.
 echo.
 ECHO ================================================================
 echo Downloading Adobe Flash for Internet Explorer...
 ECHO ================================================================
 echo.
 %WGET% -q --show-progress --no-hsts --no-check-certificate -O install_flash_player_ax.exe "http://fpdownload.adobe.com/get/flashplayer/pdc/%FlashVersion%/install_flash_player_ax.exe"

 echo.
 echo.
 ECHO ================================================================
 echo Installing Adobe Flash for Internet Explorer...
 ECHO ================================================================
 echo.
 start /w install_flash_player_ax.exe -install
 del /q /f install_flash_player_ax.exe >nul 2>&1

)


if not "%InstallFlashNP%"=="0" (

 echo.
 echo.
 ECHO ================================================================
 echo Downloading Adobe Flash for Firefox...
 ECHO ================================================================
 echo.
 %WGET% -q --show-progress --no-hsts --no-check-certificate -O install_flash_player.exe "http://fpdownload.adobe.com/get/flashplayer/pdc/%FlashVersion%/install_flash_player.exe"

 echo.
 echo.
 ECHO ================================================================
 echo Installing Adobe Flash for Firefox...
 ECHO ================================================================
 echo.
 start /w install_flash_player.exe -install
 del /q /f install_flash_player.exe >nul 2>&1

)

if not "%InstallFlashPP%"=="0" (

 echo.
 echo.
 ECHO ================================================================
 echo Downloading Adobe Flash for Opera...
 ECHO ================================================================
 echo.
 %WGET% -q --show-progress --no-hsts --no-check-certificate -O install_flash_player_ppapi.exe "http://fpdownload.adobe.com/get/flashplayer/pdc/%FlashVersion%/install_flash_player_ppapi.exe"

 echo.
 echo.
 ECHO ================================================================
 echo Installing Adobe Flash for Opera...
 ECHO ================================================================
 echo.
 start /w install_flash_player_ppapi.exe -install
 del /q /f install_flash_player_ppapi.exe >nul 2>&1

)

goto end

:errorFlashPlayer
pause >nul
:end
exit
