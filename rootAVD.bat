@echo off
SetLocal EnableDelayedExpansion
REM ##########################################################################################
REM #
REM # Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
REM # modded by NewBit XDA for Android Studio AVD
REM # Successfully tested on Android API:
REM # [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
REM # [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
REM #
REM ##########################################################################################

if "%1" == "" (
    echo "rootAVD needs a path with file to an AVD ramdisk"
    echo "rootAVD will backup your ramdisk.img and replace it when finished"
	echo "rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-30\google_apis_playstore\x86_64\ramdisk.img"
	exit /B 0
)

set RAMDISKFILE=%1
set BACKUPFILE=%RAMDISKFILE%.bak
set ROOTAVD="%cd%"
set MAGISKZIP=%ROOTAVD%\Magisk.zip
IF NOT EXIST %RAMDISKFILE% (
    echo "[!] %RAMDISKFILE% doesn't exist"
	exit /B 0
)

IF NOT EXIST %BACKUPFILE% (
    echo "[*] create Backup File"
	copy %RAMDISKFILE% %BACKUPFILE%
) ELSE (
    echo "[-] Backup exists already"
)
set ADBWORKS=
adb shell -n echo true > tmpFile 
set /P ADBWORKS=<tmpFile
del tmpFile
echo ADBWORKS=%ADBWORKS%

IF "%ADBWORKS%" == "true" (    
	echo "[-] ADB connectoin possible"
) ELSE (
    echo "[*] no ADB connectoin possible"
	exit /B 0
)

echo "[-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell"
SET ADBWORKDIR=/data/data/com.android.shell

echo "[*] Just in case, cleaning up the Magisk DIR"
rmdir /S /Q %ROOTAVD%\Magisk

echo "[*] Also, cleaning up the ADB working space"
adb shell rm -rf %ADBWORKDIR%/Magisk

echo "[*] looking for Magisk installer Zip"
IF EXIST %MAGISKZIP% (
    echo "[*] unpacking Magisk installer Zip"
	md %ROOTAVD%\Magisk
	tar -xf %MAGISKZIP%  --directory %ROOTAVD%\Magisk
	adb push %ROOTAVD%\Magisk %ADBWORKDIR%
) ELSE (
    echo "[-] Please download Magisk.zip file"
	exit /B 0
)

echo "[*] Copy the original AVD ramdisk.img into Magisk DIR"
adb push %RAMDISKFILE% %ADBWORKDIR%/Magisk

echo "[-] Copy Magisk Installer into Magisk DIR"
adb push rootAVD.sh %ADBWORKDIR%/Magisk

echo "[-] Convert Script to Unix Ending"
adb -e shell "dos2unix %ADBWORKDIR%/Magisk/rootAVD.sh"

echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
adb shell sh %ADBWORKDIR%/Magisk/rootAVD.sh "ranchu"
echo "[-] After the ramdisk.img file is patched and back gz'ed,"
echo "[*] pull it back in the Magisk DIR"
adb pull %ADBWORKDIR%/Magisk/ramdiskpatched4AVD.img

echo "[-] Clean up the ADB working space"
adb shell rm -rf %ADBWORKDIR%/Magisk
rmdir /S /Q %ROOTAVD%\Magisk

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
adb install -r %%i
)
EXIT /B 0
