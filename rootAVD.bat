@echo off
SetLocal EnableDelayedExpansion
REM ##########################################################################################
REM #
REM # Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
REM # modded by NewBit XDA for Android Studio AVD
REM # Successfully tested on Android API:
REM # [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
REM # [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
REM # [Mar. 2021] - 30 Android (S) Google Apis Play Store x86_64 Production Build rev 1
REM # [Mar. 2021] - 30 Android (S) Google Apis Play Store x86_64 Production Build rev 2
REM #
REM ##########################################################################################
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-S\google_apis_playstore\x86_64\ramdisk.img
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-30\google_apis_playstore\x86_64\ramdisk.img
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-29\google_apis_playstore\x86_64\ramdisk.img

if "%1" == "" (
    echo "rootAVD needs a path with file to an AVD ramdisk"
    echo "rootAVD will backup your ramdisk.img and replace it when finished"
	echo "rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-30\google_apis_playstore\x86_64\ramdisk.img"
	echo "rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-S\google_apis_playstore\x86_64\ramdisk.img"
	exit /B 0
)

set RAMDISKFILE=%1
set BACKUPFILE=%RAMDISKFILE%.bak
set ROOTAVD="%cd%"
set MAGISKZIP=%ROOTAVD%\Magisk.zip

CD %RAMDISKFILE%
IF "%ERRORLEVEL%"=="0" (
    echo "[*] Please give a PATH to a file, not just a Directory"
	exit /B 0
)

IF NOT EXIST %RAMDISKFILE% (
    echo "[*] %RAMDISKFILE% doesn't exist"
	exit /B 0
)

IF NOT EXIST %BACKUPFILE% (
    echo "[*] create Backup File"
	copy %RAMDISKFILE% %BACKUPFILE%
) ELSE (
    echo "[-] Backup exists already"
)

echo "[-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell"
set ADBWORKDIR=/data/data/com.android.shell
set ADBBASEDIR=%ADBWORKDIR%/Magisk
set ADBWORKS=
adb shell -n echo true > tmpFile 
set /P ADBWORKS=<tmpFile
del tmpFile

IF "%ADBWORKS%" == "true" (    
	echo "[-] ADB connectoin possible"
) ELSE (
    echo "[*] no ADB connectoin possible"
	exit /B 0
)
echo "[*] looking for Magisk installer Zip"
IF NOT EXIST %MAGISKZIP% (
    echo "[-] Please download Magisk.zip file"
	exit /B 0
)
echo "[*] Cleaning up the ADB working space"
adb shell rm -rf %ADBBASEDIR%

echo "[*] Creating the ADB working space"
adb shell mkdir %ADBBASEDIR%

echo "[-] Copy Magisk installer Zip"
adb push %MAGISKZIP% %ADBBASEDIR%

echo "[*] Copy the original AVD ramdisk.img into Magisk DIR"
adb push %RAMDISKFILE% %ADBBASEDIR%

echo "[-] Copy rootAVD Script into Magisk DIR"
adb push rootAVD.sh %ADBBASEDIR%

echo "[-] Convert Script to Unix Ending"
adb -e shell "dos2unix %ADBBASEDIR%/rootAVD.sh"

echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
adb shell sh %ADBBASEDIR%/rootAVD.sh "ranchu"
echo "[-] After the ramdisk.img file is patched and compressed,"
echo "[*] pull it back in the Magisk DIR"
adb pull %ADBBASEDIR%/ramdiskpatched4AVD.img

echo "[-] pull Magisk.apk to Apps\"
adb pull %ADBBASEDIR%/Magisk.apk Apps\

echo "[-] pull Magisk.zip to Apps\"
adb pull %ADBBASEDIR%/Magisk.zip

echo "[-] Clean up the ADB working space"
adb shell rm -rf %ADBBASEDIR%

echo "[*] Move and rename the patched ramdisk.img to the original AVD DIR"
copy ramdiskpatched4AVD.img %RAMDISKFILE%
del ramdiskpatched4AVD.img

call :installapps

echo "[-] reboot the AVD and see if it worked"
echo "[-] Root and Su with Magisk for Android Studio AVDs"
echo "[-] Modded by NewBit XDA - Jan. 2021"
echo "[*] Huge Credits and big Thanks to topjohnwu and shakalaca"

EXIT /B %ERRORLEVEL%
:INSTALLAPPS
ECHO "[-] Install all APKs placed in the Apps folder"
FOR %%i IN (APPS\*.apk) DO (
echo "[*] Trying to install %%i"
adb install -r -d %%i
)
EXIT /B 0
