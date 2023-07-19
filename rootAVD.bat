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
call :GetANDROIDHOME

IF %DEBUG% (
	echo [^!] We are in Debug Mode
	echo params=%params%
	echo DEBUG=%DEBUG%
	echo PATCHFSTAB=%PATCHFSTAB%
	echo GetUSBHPmodZ=%GetUSBHPmodZ%
	echo RAMDISKIMG=%RAMDISKIMG%
	echo restore=%restore%
	echo InstallKernelModules=%InstallKernelModules%
	echo InstallPrebuiltKernelModules=%InstallPrebuiltKernelModules%
	echo ListAllAVDs=%ListAllAVDs%
	echo InstallApps=%InstallApps%
	echo NOPARAMSATALL=%NOPARAMSATALL%
)


IF NOT %InstallApps% (
	REM If there is no file to work with, abort the script
	IF "%1" == "" (
		call :ShowHelpText && exit /B 0
	)
	IF %ListAllAVDs% (
		call :ShowHelpText && exit /B 0
	)
	IF NOT exist "%ANDROIDHOME%%1" (
		echo file %1 not found && exit /B 0
	)
)

REM Set Folders and FileNames
echo [*] Set Directorys
set AVDPATHWITHRDFFILE=%ANDROIDHOME%%1

for /F "delims=" %%i in ("%AVDPATHWITHRDFFILE%") do (
	set AVDPATH=%%~dpi
	set RDFFILE=%%~nxi
)

REM If we can CD into the ramdisk.img, it is not a file!
cd %AVDPATHWITHRDFFILE% >nul 2>&1
IF "%ERRORLEVEL%"=="0" (
    call :ShowHelpText && exit /B 0
)

IF %restore% (
	call :restore_backups && exit /B 0
)

call :TestADB

REM The Folder where the script was called from
set ROOTAVD=%cd%
set MAGISKZIP=%ROOTAVD%\Magisk.zip

REM Kernel Names
set BZFILE=%ROOTAVD%\bzImage
set KRFILE=kernel-ranchu

IF %InstallApps% (
	call :installapps && exit /B 0
)

set ADBWORKDIR=/data/data/com.android.shell
set ADBBASEDIR=%ADBWORKDIR%/Magisk
echo [-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell

call :TestADBWORKDIR

REM change to ROOTAVD directory
cd %ROOTAVD%

echo [*] Cleaning up the ADB working space
adb shell rm -rf %ADBBASEDIR%

echo [*] Creating the ADB working space
adb shell mkdir %ADBBASEDIR%

echo [*] looking for Magisk installer Zip
IF NOT exist "%MAGISKZIP%" (
    echo [-] Please download Magisk.zip file
) ELSE (
	call :pushtoAVD "%MAGISKZIP%"
)

REM Proceed with ramdisk
set INITRAMFS=%ROOTAVD%\initramfs.img

IF %RAMDISKIMG% (
	REM Is it a ramdisk named file?

	echo.%RDFFILE% | findstr /I ramdisk.*.img >NUL || (
		echo [!] please give a path to a ramdisk file
		exit /B 0
	)

	call :create_backup %RDFFILE%
	call :pushtoAVD "%AVDPATHWITHRDFFILE%" "ramdisk.img"

	IF %InstallKernelModules% (
		IF EXIST "%INITRAMFS%" (
			call :pushtoAVD "%INITRAMFS%"
		)
	)
)

echo [-] Copy rootAVD Script into Magisk DIR
adb push rootAVD.sh %ADBBASEDIR%

echo [-] run the actually Boot/Ramdisk/Kernel Image Patch Script
echo [*] from Magisk by topjohnwu and modded by NewBit XDA
adb shell sh %ADBBASEDIR%/rootAVD.sh %*

IF "%ERRORLEVEL%"=="0" (
	REM In Debug-Mode we can skip parts of the script
	IF NOT %DEBUG% (
		IF %RAMDISKIMG% (
			call :pullfromAVD ramdiskpatched4AVD.img "%AVDPATHWITHRDFFILE%"
			call :pullfromAVD Magisk.apk %ROOTAVD%\Apps\
			call :pullfromAVD Magisk.zip

			IF %InstallPrebuiltKernelModules% (
				call :pullfromAVD %BZFILE%
				call :InstallKernelModules
			)

			IF %InstallKernelModules% (
				call :InstallKernelModules
			)

			echo [-] Clean up the ADB working space
			adb shell rm -rf %ADBBASEDIR%

			call :installapps

			echo [-] Shut-Down and Reboot [Cold Boot Now] the AVD and see IF it worked
			echo [-] Root and Su with Magisk for Android Studio AVDs
			echo [-] Modded by NewBit XDA - Jan. 2021
			echo [*] Huge Credits and big Thanks to topjohnwu, shakalaca and vvb2060
			call :ShutDownAVD
		)
	)
)

exit /B %ERRORLEVEL%

:TestADBWORKDIR
echo [*] Testing the ADB working space
	SetLocal EnableDelayedExpansion
	set ADBWORKS=
	adb shell cd %ADBWORKDIR% > tmpFile 2>&1
	set /P ADBWORKS=<tmpFile
	del tmpFile

	echo.%ADBWORKS%| FIND /I "No such file or directory">Nul && (
		echo [^^!] %ADBWORKDIR% is not available
		call :_Exit 2> nul
	)
	echo [^^!] %ADBWORKDIR% is available
	EndLocal
exit /B 0

:ShutDownAVD
	SetLocal EnableDelayedExpansion
	set ADBPULLECHO=

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
	IF EXIST "%BZFILE%" (
		call :create_backup %KRFILE%
		echo [*] Copy %BZFILE% ^(Kernel^) into kernel-ranchu
		copy "%BZFILE%" "%AVDPATH%%KRFILE%" >Nul

		IF "%ERRORLEVEL%"=="0" (
			del "%BZFILE%" "%INITRAMFS%"
		)
	)
	EndLocal
exit /B 0

:pullfromAVD
	SetLocal EnableDelayedExpansion
	set SRC=%1
	set DST=%2
	set ADBPULLECHO=

	setlocal enableDelayedExpansion
	for /f "delims=" %%i in ("!SRC!") do (
		endlocal & REM
		set "SRC=%%~nxi"
	)

	setlocal enableDelayedExpansion
	for /f "delims=" %%i in ("!DST!") do (
		endlocal & REM
		set "DST=%%~nxi"
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
	set DST=%2
	set ADBPUSHECHO=

	setlocal enableDelayedExpansion
	for /f "delims=" %%i in ("!SRC!") do (
		endlocal & REM
		set "SRC=%%~nxi"
	)

	setlocal enableDelayedExpansion
	for /f "delims=" %%i in ("!DST!") do (
		endlocal & REM
		set "DST=%%~nxi"
	)

	IF "%DST%"=="" (
		echo [*] Push %SRC% into %ADBBASEDIR%
		adb push %1 %ADBBASEDIR% > tmpFile 2>&1
	) ELSE (
		echo [*] Push %SRC% into %ADBBASEDIR%/%DST%
		adb push %1 %ADBBASEDIR%/%DST% > tmpFile 2>&1
	)
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

	IF NOT EXIST "%AVDPATH%%BACKUPFILE%" (
    	echo [*] create Backup File
		copy "%AVDPATH%%FILE%" "%AVDPATH%%BACKUPFILE%" >Nul
		IF EXIST "%AVDPATH%%BACKUPFILE%" (
			echo [-] Backup File was created
		)
	) ELSE (
    	echo [-] Backup exists already
	)
	ENDLOCAL
exit /B 0

:TestADB
	SetLocal EnableDelayedExpansion
	set ADB_DIR=""
	set ADB_EX=""

	echo [-] Test IF ADB SHELL is working

	set ADBWORKS=
	adb shell -n echo true > tmpFile 2>&1
	set /P ADBWORKS=<tmpFile
	del tmpFile

	IF "%ADBWORKS%" == "true" (
		echo [-] ADB connection possible
	) ELSE (
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
			IF EXIST "%ANDROIDHOME%%ADB_DIR_W%" (
				set ADB_DIR=%ADB_DIR_W%
			) ELSE (
				echo [^^!] ADB not found, please install platform-tools and add it to your %%PATH%%
				call :_Exit 2> nul
			)

			for /f "delims=" %%i in ('dir "%ANDROIDHOME%%ADB_DIR%adb.exe" /s /b /a-d') do (
				set ADB_EX=%%i
			)

			IF "!ADB_EX!" == "" (
				echo [^^!] ADB binary not found in %ENVVAR%\%ADB_DIR%
				call :_Exit 2> nul
			)

  			echo [^^!] ADB is not in your Path, try to
  			echo set PATH=%ENVVAR%\!ADB_DIR!;%%PATH%%

			IF EXIST "!ADB_EX!" (
				echo [*] setting it, just during this session, for you
				set "PATH=%ANDROIDHOME%!ADB_DIR!;%PATH%"
				REM goto :TestADB
				call :TestADB
			)
		)

		echo.%ADBWORKS%| FIND /I "error">Nul && (
			echo [^^!] %ADBWORKS%
  			echo [*] no ADB connection possible
  			call :_Exit 2> nul
		)

		echo.%ADBWORKS%| FIND /I "no devices/emulators found">Nul && (
			echo [^^!] %ADBWORKS%
  			echo [*] no ADB connection possible
  			call :_Exit 2> nul
		)
	)
	IF EXIST "!ADB_EX!" (
		ENDLOCAL & set "PATH=%PATH%"
    ) ELSE (
    	ENDLOCAL
    )
exit /B 0

:restore_backups
	for /f "delims=" %%i in ('dir "%AVDPATH%*.backup" /s /b /a-d') do (
		echo [^!] Restoring %%~ni%%~xi to %%~ni
		copy "%%i" "%%~di%%~pi%%~ni" >nul 2>&1
	)
	echo [*] Backups still remain in place
REM call :_Exit 2> nul
exit /B 0

:ProcessArguments
	set params=%*
	set DEBUG=%false%
	set PATCHFSTAB=%false%
	set GetUSBHPmodZ=%false%
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

    set RAMDISKIMG=%true%

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
	echo Usage:	rootAVD [DIR/ramdisk.img] [OPTIONS] ^| [EXTRA ARGUMENTS]
	echo or:	rootAVD [ARGUMENTS]
	echo.
	echo Arguments:
	echo 	ListAllAVDs			Lists Command Examples for ALL installed AVDs
	echo.
	echo 	InstallApps			Just install all APKs placed in the Apps folder
	echo.
	echo Main operation mode:
	echo 	DIR				a path to an AVD system-image
	echo 					- must always be the 1st Argument after rootAVD
	echo.
	echo ADB Path ^| Ramdisk DIR^| ANDROID_HOME:
	echo 	[M]ac/Darwin:			export PATH=~/Library/Android/sdk/platform-tools:^$PATH
	echo 					export PATH=^$ANDROID_HOME/platform-tools:^$PATH
	echo 					system-images/android-^$API/google_apis_playstore/x86_64/
	echo.
	echo 	[L]inux:			export PATH=~/Android/Sdk/platform-tools:^$PATH
	echo 					export PATH=^$ANDROID_HOME/platform-tools:^$PATH
	echo 					system-images/android-^$API/google_apis_playstore/x86_64/
	echo.
	echo 	[W]indows:			set PATH=%ENVVAR%\%ADB_DIR_W%;%%PATH%%
	echo 					system-images\android-^$API\google_apis_playstore\x86_64\
	echo.
	echo 	ANDROID_HOME:			By default, the script uses %%LOCALAPPDATA%%, to set its Android Home
	echo 					directory, search for AVD system-images and ADB binarys. This behaviour
	echo 					can be overwritten by setting the ANDROID_HOME variable.
	echo 					e.g. set ANDROID_HOME=%%USERPROFILE%%\Downloads\sdk
	echo.
	echo 	^$API:				25,29,30,31,32,33,34,UpsideDownCake,etc.
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
	echo Extra Arguments:
	echo 	DEBUG				Debugging Mode, prevents rootAVD to pull back any patched file
	echo.
	echo 	PATCHFSTAB			fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
	echo 					- other entries can be added in the script as well
	echo 					- a custom build Kernel might be necessary
	echo.
	echo 	GetUSBHPmodZ			The USB HOST Permissions Module Zip will be downloaded into /sdcard/Download
	echo.
	echo 	FAKEBOOTIMG			Creates a fake Boot.img file that can directly be patched from the Magisk APP
	echo 					- Magisk will be launched to patch the fake Boot.img within 60s
	echo 					- the fake Boot.img will be placed under /sdcard/Download/fakeboot.img
	echo.
	echo Extra Arguments can be combined, there is no particular order.
	echo.
	echo Notes: rootAVD will
	echo - always create .backup files of ramdisk*.img and kernel-ranchu
	echo - replace both when done patching
	echo - show a Menu, to choose the Magisk Version (Stable ^|^| Canary ^|^| Alpha), if the AVD is online
	echo - make the choosen Magisk Version to its local
	echo - install all APKs placed in the Apps folder
	call :FindSystemImages
exit /B 0

:GetANDROIDHOME
	REM set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
	REM set ANDROID_HOME=%USERPROFILE%\Downloads\sdk
	REM set ANDROID_HOME="%USERPROFILE%\Downloads\sd k"
	REM set ANDROID_HOME=%USERPROFILE%\Downloads\sd k
	REM set ANDROID_HOME=%USERPROFILE%\Downloads\Program Files (x86)\Android\android-sdk
	REM set ANDROID_HOME="%USERPROFILE%\Downloads\Program Files (x86)\Android\android-sdk"
	set NoSystemImages=%true%

	REM Default: Looking for LOCALAPPDATA to seach AVD system-images
	set ENVVAR=%%LOCALAPPDATA%%\Android\Sdk
	set ANDROIDHOME=%LOCALAPPDATA%\Android\Sdk\

	IF defined ANDROID_HOME (
        set ENVVAR=%%ANDROID_HOME%%
        setlocal enableDelayedExpansion
		for /f "delims=" %%A in ("!ANDROID_HOME!") do (
			endlocal & REM
			set "ANDROID_HOME=%%~A"
			set "ANDROIDHOME=%%~A\"
		)
    )

	set SYSIM_DIR_W=system-images\
	set ADB_DIR_W=platform-tools

	IF EXIST "%ANDROIDHOME%%SYSIM_DIR_W%" (
		set SYSIM_DIR=%SYSIM_DIR_W%
		set NoSystemImages=%false%
	)
exit /B 0

:FindSystemImages
	echo - use %ENVVAR% to search for AVD system images
	echo.
	SetLocal EnableDelayedExpansion
	set SYSIM_EX=

	IF %NoSystemImages% (
		echo Neither system-images nor ramdisk files could be found
		exit /B 1
	)

	for /f "delims=" %%i in ('dir "%ANDROIDHOME%%SYSIM_DIR%ramdisk*.img" /s /b /a-d') do (
		set "j=%%~i"
		setlocal enableDelayedExpansion
		for /f "delims=" %%a in ("!ANDROIDHOME!") do (
			endlocal & REM
			set "j=!j:%%a=!"
		)

		IF %ListAllAVDs% (
			IF "!SYSIM_EX!" == "" (
				set SYSIM_EX=!j!
			) ELSE (
				set SYSIM_EX=!j! !SYSIM_EX!
			)
		) ELSE (
			set SYSIM_EX=!j!
		)
	)

	echo Command Examples:
	echo rootAVD.bat
	echo rootAVD.bat ListAllAVDs
	echo rootAVD.bat InstallApps
	echo.

	for %%i in (%SYSIM_EX%) do (
		echo rootAVD.bat %%i
		echo rootAVD.bat %%i FAKEBOOTIMG
		echo rootAVD.bat %%i DEBUG PATCHFSTAB GetUSBHPmodZ
		echo rootAVD.bat %%i restore
		echo rootAVD.bat %%i InstallKernelModules
		echo rootAVD.bat %%i InstallPrebuiltKernelModules
		echo rootAVD.bat %%i InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
		echo.
	)
	ENDLOCAL
exit /B 0

:_Exit
IF %NOPARAMSATALL% (
	cmd /k
)
()
goto :eof
