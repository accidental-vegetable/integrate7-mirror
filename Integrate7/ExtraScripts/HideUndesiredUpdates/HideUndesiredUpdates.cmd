@echo off
title Hide Undesired Updates

echo.
echo ======================================================
echo Hiding undesired updates (this may take a while) ...
echo ======================================================
echo.

powershell -executionpolicy bypass -file "%~dp0hide.ps1"

echo.
echo.

sc query wuauserv 2>&1 | findstr /i running >nul 2>&1 && net stop wuauserv
sc query bits 2>&1 | findstr /i running >nul 2>&1 && net stop bits
net start bits
net start wuauserv

echo.
echo Finished!
echo.
exit
