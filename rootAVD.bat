@echo off
SetLocal DisableDelayedExpansion
set true=1==1
set false=1==0

REM ##########################################################################################
REM #
REM # Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
REM # modded by NewBit XDA for Android Studio AVD
REM # Successfully tested on Android API:
REM # [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
REM # [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
REM # [Apr. 2021] - 30 Android (S) Google Apis Play Store x86_64 Production Build rev 3
REM #
REM ##########################################################################################
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-S\google_apis_playstore\x86_64\ramdisk.img
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-30\google_apis_playstore\x86_64\ramdisk.img
REM rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-29\google_apis_playstore\x86_64\ramdisk.img

call :ProcessArguments %*

if %DEBUG% (
	echo [^!] We are in Debug Mode
	REM echo on
)

if not %ENVFIXTASK% (
	if not %InstallApps% (
		REM If there is no file to work with, abort the script
		if not exist "%1" (
			call :ShowHelpText
		)
	)
)

REM Set Folders and FileNames
echo [*] Set Directorys
set AVDPATHWITHRDFFILE=%1
for /F "delims=" %%i in ("%AVDPATHWITHRDFFILE%") do (
	set AVDPATH=%%~dpi
	set RDFFILE=%%~nxi
)

REM If we can CD into the ramdisk.img, it is not a file!
cd %AVDPATHWITHRDFFILE% >nul 2>&1
if "%ERRORLEVEL%"=="0" (
    call :ShowHelpText
)

if %restore% (
	call :restore_backups
)

call :TestADB

REM The Folder where the script was called from
set ROOTAVD=%cd%
set MAGISKZIP=%ROOTAVD%\Magisk.zip

REM Kernel Names
set BZFILE=%ROOTAVD%\bzImage
set KRFILE=kernel-ranchu

if %InstallApps% (
	call :installapps
	call :_Exit 2> nul
)

set ADBWORKDIR=/data/data/com.android.shell
set ADBBASEDIR=%ADBWORKDIR%/Magisk
echo [-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell

REM change to ROOTAVD directory
cd %ROOTAVD%

echo [*] looking for Magisk installer Zip
if not exist "%MAGISKZIP%" (
    echo [-] Please download Magisk.zip file
	call :_Exit 2> nul
)

echo [*] Cleaning up the ADB working space
adb shell rm -rf %ADBBASEDIR%

echo [*] Creating the ADB working space
adb shell mkdir %ADBBASEDIR%

call :pushtoAVD "%MAGISKZIP%"
REM Proceed with ramdisk
set INITRAMFS=%ROOTAVD%\initramfs.img
if %RAMDISKIMG% (
	REM Is it a ramdisk named file?
	if not "%RDFFILE%" == "ramdisk.img" (
		echo [!] please give a path to a ramdisk file
		call :_Exit 2> nul
	)
	call :create_backup %RDFFILE%
	call :pushtoAVD "%AVDPATHWITHRDFFILE%"

	if %InstallKernelModules% (
		if exist "%INITRAMFS%" (
			call :pushtoAVD "%INITRAMFS%"
		)
	)
)

echo [-] Copy rootAVD Script into Magisk DIR
adb push rootAVD.sh %ADBBASEDIR%

REM echo [-] Convert Script to Unix Ending
REM adb -e shell "dos2unix %ADBBASEDIR%/rootAVD.sh"

echo [-] run the actually Boot/Ramdisk/Kernel Image Patch Script
echo [*] from Magisk by topjohnwu and modded by NewBit XDA
adb shell sh %ADBBASEDIR%/rootAVD.sh %*

if "%ERRORLEVEL%"=="0" (
	REM In Debug-Mode we can skip parts of the script
	if not %DEBUG% (
		if %RAMDISKIMG% (
			call :pullfromAVD ramdiskpatched4AVD.img %AVDPATHWITHRDFFILE%
			call :pullfromAVD Magisk.apk %ROOTAVD%\Apps\
			call :pullfromAVD Magisk.zip

			if %InstallPrebuiltKernelModules% (
				call :pullfromAVD %BZFILE%
				call :InstallKernelModules
			)

			if %InstallKernelModules% (
				call :InstallKernelModules
			)

			echo [-] Clean up the ADB working space
			adb shell rm -rf %ADBBASEDIR%

			call :installapps

			echo [-] Shut-Down and Reboot [Cold Boot Now] the AVD and see if it worked
			echo [-] Root and Su with Magisk for Android Studio AVDs
			echo [-] Modded by NewBit XDA - Jan. 2021
			echo [*] Huge Credits and big Thanks to topjohnwu, shakalaca and vvb2060
			call :ShutDownAVD
		)
	)
)

exit /B %ERRORLEVEL%

:ShutDownAVD
	SetLocal EnableDelayedExpansion
	set ADBPULLECHO=
	
	REM adb shell reboot -p > tmpFile 2>&1
	adb shell setprop sys.powerctl shutdown > tmpFile 2>&1
	set /P ADBPULLECHO=<tmpFile
	del tmpFile

	echo.%ADBPULLECHO%| FIND /I "error">Nul || (
  		echo [-] Trying to shut down the AVD
	)
	echo [^^!] If the AVD doesnt shut down, try it manually^^!

	EndLocal
exit /B 0

:InstallKernelModules
	SetLocal EnableDelayedExpansion
	if exist "%BZFILE%" (
		call :create_backup %KRFILE%
		echo [*] Copy %BZFILE% ^(Kernel^) into kernel-ranchu
		copy %BZFILE% %AVDPATH%%KRFILE% >Nul

		if "%ERRORLEVEL%"=="0" (
			del %BZFILE% %INITRAMFS%
		)
	)
	EndLocal
exit /B 0

:pullfromAVD
	SetLocal EnableDelayedExpansion
	set SRC=%1
	set DST=%2
	set ADBPULLECHO=

	for /F "delims=" %%i in ("%SRC%") do (
		set SRC=%%~nxi
	)

	for /F "delims=" %%i in ("%DST%") do (
		set DST=%%~nxi
	)

	adb pull %ADBBASEDIR%/%SRC% %2 > tmpFile 2>&1
	set /P ADBPULLECHO=<tmpFile
	del tmpFile

	echo.%ADBPULLECHO%| FIND /I "error">Nul || (
  		echo [*] Pull %SRC% into %DST%
  		echo [-] %ADBPULLECHO%
	)
	EndLocal
exit /B 0

:pushtoAVD
	SetLocal EnableDelayedExpansion
	set SRC=%1
	set ADBPUSHECHO=

	for /F "delims=" %%i in ("%SRC%") do (
		set SRC=%%~nxi
	)

	echo [*] Push %SRC% into %ADBBASEDIR%
	adb push %1 %ADBBASEDIR% > tmpFile 2>&1
	set /P ADBPUSHECHO=<tmpFile
	del tmpFile

	echo [-] %ADBPUSHECHO%
	ENDLOCAL
exit /B 0

:create_backup
	SetLocal EnableDelayedExpansion
	set FILE=%1
	set BACKUPFILE=%FILE%.backup

	REM If no backup file exist, create one

	if not exist %AVDPATH%%BACKUPFILE% (
    	echo [*] create Backup File
		copy %AVDPATH%%FILE% %AVDPATH%%BACKUPFILE% >Nul
	) else (
    	echo [-] Backup exists already
	)
	ENDLOCAL
exit /B 0

:TestADB
	SetLocal EnableDelayedExpansion
	set HOME=%LOCALAPPDATA%\
	set ADB_DIR_W=Android\Sdk\platform-tools\
	set ADB_DIR=""
	set ADB_EX=""

	echo [-] Test if ADB SHELL is working
	
	set ADBWORKS=
	adb shell -n echo true > tmpFile 2>&1
	set /P ADBWORKS=<tmpFile
	del tmpFile

	if "%ADBWORKS%" == "true" (
		echo [-] ADB connectoin possible
	) else (
		
		echo.%ADBWORKS%| FIND /I "offline">Nul && (
  			echo [^^!] ADB device is offline
  			echo [*] no ADB connection possible
  			call :_Exit 2> nul
		)
		
		echo.%ADBWORKS%| FIND /I "unauthorized">Nul && (
  			echo [^^!] %ADBWORKS%
  			echo [*] no ADB connection possible
  			call :_Exit 2> nul
		)
		
		echo.%ADBWORKS%| FIND /I "recognized">Nul && (
			if exist %HOME%%ADB_DIR_W% (
				set ADB_DIR=%ADB_DIR_W%
			) else (
				echo [^^!] ADB not found, please install platform-tools and add it to your %%PATH%%
				call :_Exit 2> nul
			)
			
			for /f "delims=" %%i in ('dir %HOME%%ADB_DIR%adb.exe /s /b /a-d') do (
				set ADB_EX=%%i
			)

			if !ADB_EX! == "" (
				echo [^^!] ADB binary not found in %%LOCALAPPDATA%%\%ADB_DIR%
				call :_Exit 2> nul
			)

  			echo [^^!] ADB is not in your Path, try to
  			echo set PATH=%%LOCALAPPDATA%%\Android\Sdk\platform-tools;%%PATH%%
  			call :_Exit 2> nul
		)
		
		echo.%ADBWORKS%| FIND /I "error">Nul && (
			echo [^^!] %ADBWORKS%
  			echo [*] no ADB connection possible  			
  			call :_Exit 2> nul
		)
		call :_Exit 2> nul
	)	
	ENDLOCAL
exit /B 0

:restore_backups
	for /f "delims=" %%i in ('dir %AVDPATH%*.backup /s /b /a-d') do (
		echo [^!] Restoring %%~ni%%~xi to %%~ni
		copy %%i %%~di%%~pi%%~ni >nul 2>&1
	)
	echo [*] Backups still remain in place
call :_Exit 2> nul

:ProcessArguments
	set params=%*
	set DEBUG=%false%
	set PATCHFSTAB=%false%
	set GetUSBHPmodZ=%false%
	set ENVFIXTASK=%false%
	set RAMDISKIMG=%false%
	set restore=%false%
	set InstallKernelModules=%false%
	set InstallPrebuiltKernelModules=%false%
	set ListAllAVDs=%false%
	set InstallApps=%false%
	set NOPARAMSATALL=%false%

	REM While debugging and developing you can turn this flag on
	echo.%params%| FIND /I "DEBUG">Nul && (
  		set DEBUG=%true%
  		REM Shows whatever line get executed...
  		REM echo on
	)

	REM Call rootAVD with PATCHFSTAB if you want the RAMDISK merge your modded fstab.ranchu before Magisk Mirror gets mounted
	echo.%params%| FIND /I "PATCHFSTAB">Nul && (
  		set PATCHFSTAB=%true%
	)

	REM Call rootAVD with GetUSBHPmodZ to download the usbhostpermissons module
	echo.%params%| FIND /I "GetUSBHPmodZ">Nul && (
  		set GetUSBHPmodZ=%true%
	)

	REM Call rootAVD with ListAllAVDs to show all AVDs with command examples
	echo.%params%| FIND /I "ListAllAVDs">Nul && (
  		set ListAllAVDs=%true%
	)

	REM Call rootAVD with InstallApps to just install all APKs placed in the Apps folder
	echo.%params%| FIND /I "InstallApps">Nul && (
  		set InstallApps=%true%
	)

	IF "%1"=="EnvFixTask" (
		REM AVD requires additional setup
    	set ENVFIXTASK=%true%
	) ELSE (
    	set RAMDISKIMG=%true%
	)

	IF "%2" == "restore" (
    	set restore=%true%
	) ELSE IF "%2"=="InstallKernelModules" (
    	set InstallKernelModules=%true%
	) ELSE IF "%2"=="InstallPrebuiltKernelModules" (
		set InstallPrebuiltKernelModules=%true%
	)
	
	IF "%params%"=="" (
		REM No Parameters SET at all
    	set NOPARAMSATALL=%true%
	)
exit /B 0

:installapps
	SetLocal EnableDelayedExpansion
	echo [-] Install all APKs placed in the Apps folder
	for %%i in (APPS\*.apk) do (		
		set APK=%%i
		:whileloop
			echo [*] Trying to install !APK!			
			for /f "delims=" %%A in ('adb install -r -d !APK! 2^>^&1' ) do (
				echo [-] %%A
				echo.%%A| FIND /I "INSTALL_FAILED_UPDATE_INCOMPATIBLE">Nul && (
					set Package=					
					for %%p in (%%A) do (
						echo.!Package!| FIND /I "Package">Nul && (
							echo [*] Need to uninstall %%p first						
							adb uninstall %%p > tmpFile 2>&1
							set /P ADBECHO=<tmpFile
							del tmpFile
							echo [-] !ADBECHO!
							goto :whileloop
						)
						set Package=%%p
					)
				)				
			)
	)
	ENDLOCAL
exit /B 0

:ShowHelpText
	echo rootAVD A Script to root AVD by NewBit XDA
	echo.
	echo Usage:	rootAVD [DIR/ramdisk.img] [OPTIONS] ^| [EXTRA_CMDS]
	echo or:	rootAVD [ARGUMENTS]
	echo.
	echo Arguments:
	echo 	ListAllAVDs			Lists Command Examples for ALL installed AVDs
	echo.
	echo 	EnvFixTask			Requires Additional Setup fix
	echo 					- construct Magisk Environment manual
	echo 					- only works with an already Magisk patched ramdisk.img
	echo 					- without [DIR/ramdisk.img] [OPTIONS] [PATCHFSTAB]
	echo 					- needed since Android 12 (S) rev.1
	echo 					- not needed anymore since Android 12 (S) API 31 and Magisk Alpha
	echo 					- Grant Shell Su Permissions will pop up a few times
	echo 					- the AVD will reboot automatically
	echo.
	echo 	InstallApps			Just install all APKs placed in the Apps folder
	echo.
	echo Main operation mode:
	echo 	DIR				a path to an AVD system-image
	echo 					- must always be the 1st Argument after rootAVD
	echo.
	echo ADB Path ^| Ramdisk DIR:
	echo 	[M]ac/Darwin:			export PATH=~/Library/Android/sdk/platform-tools:\$PATH
	echo 					~/Library/Android/sdk/system-images/android-\$API/google_apis_playstore/x86_64/
	echo.
	echo 	[L]inux:			export PATH=~/Android/Sdk/platform-tools:\$PATH
	echo 					~/Android/Sdk/system-images/android-\$API/google_apis_playstore/x86_64/
	echo.
	echo 	[W]indows:			set PATH=%%LOCALAPPDATA%%\Android\Sdk\platform-tools;%%PATH%%
	echo 					%%LOCALAPPDATA%%\Android\Sdk\system-images\android-^$API\google_apis_playstore\x86_64\
	echo.
	echo 	^$API:				25,29,30,S,etc.
	echo.
	echo Except for EnvFixTask, ramdisk.img must be untouched (stock).
	echo.
	echo Options:
	echo 	restore				restore all existing .backup files, but doesn't delete them
	echo 					- the AVD doesn't need to be running
	echo 					- no other Argument after will be processed
	echo.
	echo 	InstallKernelModules		install custom build kernel and its modules into ramdisk.img
	echo 					- kernel (bzImage) and its modules (initramfs.img) are inside rootAVD
	echo 					- both files will be deleted after installation
	echo.
	echo 	InstallPrebuiltKernelModules	download and install an AOSP prebuilt kernel and its modules into ramdisk.img
	echo 					- similar to InstallKernelModules, but the AVD needs to be online
	echo.
	echo Options are exclusive, only one at the time will be processed.
	echo.
	echo Extra Commands:
	echo 	DEBUG				Debugging Mode, prevents rootAVD to pull back any patched file
	echo.
	echo 	PATCHFSTAB			fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
	echo 					- other entries can be added in the script as well
	echo 					- a custom build Kernel might be necessary
	echo.
	echo 	GetUSBHPmodZ			The USB HOST Permissions Module Zip will be downloaded into /sdcard/Download
	echo.
	echo Extra Commands can be combined, there is no particular order.
	echo.
	echo Notes: rootAVD will
	echo - always create .backup files of ramdisk.img and kernel-ranchu
	echo - replace both when done patching
	echo - show a Menu, to choose the Magisk Version (Stable ^|^| Canary ^|^| Alpha), if the AVD is online
	echo - make the choosen Magisk Version to its local
	echo - install all APKs placed in the Apps folder
	echo.
	echo Command Examples:
	call :FindSystemImages
call :_Exit 2> nul

:FindSystemImages
	SetLocal EnableDelayedExpansion
	set HOME=%LOCALAPPDATA%\
	set SYSIM_DIR_W=Android\Sdk\system-images\
	set SYSIM_DIR=
	set SYSIM_EX=

	IF EXIST %HOME%%SYSIM_DIR_W% (
        set SYSIM_DIR=%SYSIM_DIR_W%
    ) ELSE (
        exit /B 0
    )

	for /f "delims=" %%i in ('dir %HOME%%SYSIM_DIR%ramdisk.img /s /b /a-d') do (
		if %ListAllAVDs% (
			set SYSIM_EX=%%i !SYSIM_EX!
		)ELSE (
			set SYSIM_EX=%%i
		)		
	)

	call set SYSIM_EX=%%SYSIM_EX:!HOME!=%%

	echo rootAVD.bat
	echo rootAVD.bat ListAllAVDs
	echo rootAVD.bat EnvFixTask
	echo rootAVD.bat InstallApps
	echo.

	for %%i in (%SYSIM_EX%) do (
		IF NOT %%i == "" (
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i DEBUG PATCHFSTAB GetUSBHPmodZ
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i restore
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i InstallKernelModules
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i InstallPrebuiltKernelModules
			echo rootAVD.bat %%LOCALAPPDATA%%\%%i InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
			echo.
		)
	)
	ENDLOCAL
exit /B 0

:_Exit
if %NOPARAMSATALL% (
	cmd /k
)
()
goto :eof
