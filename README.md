# rootAVD
### [newbit @ xda-developers](https://forum.xda-developers.com/m/newbit.1350876)
A Script to...
* root your Android Studio Virtual Device (AVD), with Magisk (Stable or Canary)
* patch its fstab
* download and install the USB HOST Permissions Module for Magisk
* install custom build Kernel and its Modules
* download and install AOSP prebuilt Kernel and its Modules

...within seconds.

## Install Magisk
### Preconditions
* the AVD is running
* a working Internet connection for the Menu
* a command prompt / terminal is opened
* `adb shell` will connect to the running AVD

## rootAVD Help Menu
### Linux & MacOS
```
./rootAVD.sh
rootAVD A Script to root AVD by NewBit XDA

Usage:	rootAVD [DIR/ramdisk.img] [OPTIONS] | [EXTRA_CMDS]
or:	rootAVD EnvFixTask

Requires Additional Setup fix:
	EnvFixTask			construct Magisk Environment manual
					- only works with an already Magisk patched ramdisk.img
					- without [DIR/ramdisk.img] [OPTIONS] [PATCHFSTAB]
					- needed since Android 12 (S) rev.1
					- Grant Shell Su Permissions will pop up a few times
					- the AVD will reboot automatically
	
Main operation mode:
	DIR				a path to an AVD system-image
					- must always be the 1st Argument after rootAVD
	
ADB Path | Ramdisk DIR:
	[M]ac/Darwin:			export PATH=~/Library/Android/sdk/platform-tools:$PATH
					~/Library/Android/sdk/system-images/android-$API/google_apis_playstore/x86_64/
	
	[L]inux:			export PATH=~/Android/Sdk/platform-tools:$PATH
					~/Android/Sdk/system-images/android-$API/google_apis_playstore/x86_64/
	
	[W]indows:			set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
					%LOCALAPPDATA%\Android\Sdk\system-images\android-$API\google_apis_playstore\x86_64\
	
	$API:				25,29,30,S,etc.
	
Except for EnvFixTask, ramdisk.img must be untouched (stock).
	
Options:
	restore				restore all existing .backup files, but doesn't delete them
					- the AVD doesn't need to be running
					- no other Argument after will be processed
	
	InstallKernelModules		install custom build kernel and its modules into ramdisk.img
					- kernel (bzImage) and its modules (initramfs.img) are inside rootAVD
					- both files will be deleted after installation
	
	InstallPrebuiltKernelModules	download and install an AOSP prebuilt kernel and its modules into ramdisk.img
					- similar to InstallKernelModules, but the AVD needs to be online
	
Options are exclusive, only one at the time will be processed.
	
Extra Commands:
	DEBUG				Debugging Mode, prevents rootAVD to pull back any patched file
	
	PATCHFSTAB			fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
					- other entries can be added in the script as well
					- a custom build Kernel might be necessary
	
	GetUSBHPmodZ			The USB HOST Permissions Module Zip will be downloaded into /sdcard/Download
	
Extra Commands can be combined, there is no particular order.
	
Notes: rootAVD will
- always create .backup files of ramdisk.img and kernel-ranchu
- replace both when done patching
- show a Menu, to choose the Magisk Version (Stable || Canary), if the AVD is online
- make the choosen Magisk Version to its local
- install all APKs placed in the Apps folder
	
Command Examples:
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh EnvFixTask
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img restore
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img InstallKernelModules
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules DEBUG PATCHFSTAB GetUSBHPmodZ
```

#### Windows
```
set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-S\google_apis_playstore\x86_64\ramdisk.img
```

### Notes
* Android 12 (S) rev.2 needs Magisk v22.1+ or Canary
* With the new Menu, you can choose between the newest Magisk, Canary and Stable, Version.
* Once choosen, the script will make that Version to your local one.
* Prebuilt Kernel and Modules will be pulled from [AOSP](https://android.googlesource.com/kernel/prebuilts)

### 2 Ways to boot the AVD into Safe Mode
* 1st Way - If the AVD still boots normal:
	* Tap and Hold the **Power Button** until the 3 Options appear
	* Tap and Hold the **Power Off Button** until **Reboot to safe mode** appears
* 2nd Way - If the AVD stuck while booting (**black** screen):
	* Tap and Hold the **Volume Down Button**
	* The Time Window is between the **Launching Emulator Bar** is approx **half way** until the **Google Boot Screen** appears
* Confirmation
	* On the Bottom Left Corner reads: **Safe mode**

### Links
* [XDA [GUIDE] Build / Mod AVD Kernel Android 10 / 11 rootAVD [Magisk] [USB passthrough Linux] [Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-avd-kernel-android10-x86_64-29-root-magisk-usb-passthrough-linux.4212719)
* [Inject Android Hardware USB HOST Permissions](https://github.com/newbit1/usbhostpermissons)
* [XDA [SCRIPT] rootAVD - root your Android Studio Virtual Device emulator with Magisk [Android 11][Linux][Darwin/MacOS][WIN][Google Play Store APIs]](https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-11-linux-darwin-macos-win-google-play-store-apis.4218123)

### XDA [GUIDE] How to [Build|Mod|Update] a custom AVD Kernel and its Modules
* [[GUIDE][Build|Mod|Update][kernel-ranchu][goldfish][5.4][5.10][GKI][ramdisk.img][modules][rootAVD][Android 11(R) 12(S)][AVD][Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-update-kernel-ranchu-goldfish-5-4-5-10-gki-ramdisk-img-modules-rootavd-android-11-r-12-s-avd-google-play-store-api.4220697)

### Magisk v22.1+ Successfully tested with Stock Kernel on
* [[Apr. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r03 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r03-windows.zip)
* [[Apr. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r03 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r03-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r02 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r02-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r01-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r02 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r02-windows.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r01-windows.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-S_r01.zip)
* [[Mar. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Mar. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-windows.zip)
* [[Mar. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r08 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-darwin.zip)
* [[Mar. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r08 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-windows.zip)

### Change Logs
#### [Apr. 2021]
* [General] - Added comprehensive Help Menu
* [rootAVD.sh] - Changed "DEBUG" "PATCHFSTAB" "GetUSBHPmodZ" to Arguments
* [General] - Fixed some typos and functions
* [rootAVD.sh] - Add a Menu to choose the prebuilt Kernel and Modules Version to install
* [General] - Added "InstallPrebuiltKernelModules" download/update/install prebuilt kernel and modules
* [General] - Added 2 Ways to boot the AVD into Safe Mode
* [rootAVD.sh] - Added Android S rev 3 support
* [General] - Added "InstallKernelModules" update/install custom build kernel and modules
* [rootAVD.sh] - Added update_lib_modules function
* [General] - Added "restore" to put back your backup files
* [General] - Updated local Magisk App v22.1
* [rootAVD.sh] - Added Option to Download the USB HOST Permissions Module

<details>
<summary>Archive</summary>

### Change Logs
#### [Mar. 2021]
* [General] - Add a Download Manager Function for bad TLS record using wget
* [rootAVD.bat] - Adjustments to run with the updated rootAVD.sh
* [General] - Add a Menu to choose the Magisk Version to install
* [rootAVD.sh] - Added EnvFixTask Argument to fix Requires Additional Setup in Android S
* [General] - Changed to BusyBox (D)ASH Standalone
* [General] - Re-Structured Script
* [rootAVD.sh] - Added "Additional Setup Required" manually for Android S
* [rootAVD.sh] - Updated shakalaca's Ramdisk Repack Routine
* [rootAVD.sh] - Added Compression Detection for LZ4 and GZ
* [General] - Fixed some bugs and typos
* [General] - Updated to Magisk App v22.0
### Magisk v21.4 Successfully tested with Stock Kernel on
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-windows.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-linux.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis x86_64 r11 User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-29_r11.zip)
* [[Jan. 2021] - Android  7 (Nougat) API 24 Google Apis Play Store x86 r19 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-24_r19.zip)

</details>

### Credits
* [topjohnwu @ xda-developers](https://forum.xda-developers.com/m/topjohnwu.4470081)
* [topjohnwu Magisk File Host](https://github.com/topjohnwu/magisk-files)
* [topjohnwu Magisk App](https://github.com/topjohnwu/Magisk/releases)
* [topjohnwu Magisk v21.4](https://github.com/topjohnwu/Magisk/releases/tag/v21.4)
* [topjohnwu Magisk Manager v8.0.7](https://github.com/topjohnwu/Magisk/releases/tag/manager-v8.0.7)
* [shakalaca @ xda-developers](https://forum.xda-developers.com/m/shakalaca.1813976)
* [shakalaca MagiskOnEmulator](https://github.com/shakalaca/MagiskOnEmulator)
* [Akianonymus _json_value](https://gist.github.com/cjus/1047794#gistcomment-3313785)
* [Tad Fisher Android Nixpkgs](https://github.com/tadfisher/android-nixpkgs)
