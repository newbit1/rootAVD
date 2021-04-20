# rootAVD
### [newbit @ xda-developers](https://forum.xda-developers.com/m/newbit.1350876)
A Script to root your Android Studio Virtual Device (AVD), with Magisk within seconds.

## Install Magisk
### Preconditions
* the AVD is running
* a working Internet connection for the Menu
* a command prompt / terminal is opened
* `adb shell` will connect to the running AVD

### How To Use it
* run rootAVD with a path to an AVDs ramdisk.img file
* ramdisk.img gets a backup and will be replaced when done patching

### How To Use it under Android S with Magisk v22.x
* rootAVD needs to run twice
* 1st - to patch the ramdisk.img
* 2nd - after Shut-Down & Reboot the AVD:
	* Option 1 - re-run same script command
	* Option 2 - run script with EnvFixTask Argument
		* The "Additional Setup Required" will not be triggered in Android S by Magisk App in AVD,
		* this must be done manually on the 2nd run
		* Grant Shell Su Permissions will pop up a few times
		* rootAVD will reboot the AVD automatically
		* check Magisk App !!

## Install / Update a custom build kernel and its modules
### Preconditions
* Install Magisk Preconditions
* build a kernel (bzImage) and its modules (initramfs.img)
* both files are placed inside the rootAVD directory
* ramdisk.img must be untouched (stock)

### How To Use it 
* run rootAVD with the additional InstallKernelModules parameter
* the modules inside ramdisk.img will be replaced by the modules inside initramfs.img
* kernel-ranchu gets a backup and will be placed with bzImage when done patching
* bzImage and initramfs.img will be deleted after installation

## Restore Backups of Ramdisk and kernel
### Preconditions
* none

### How To Use it
* run rootAVD with the additional restore parameter

## XDA [GUIDE] How to [Build|Mod|Update] a custom AVD Kernel and its Modules
* [[GUIDE][Build|Mod|Update][kernel-ranchu][goldfish][5.4][5.10][GKI][ramdisk.img][modules][rootAVD][Android 11(R) 12(S)][AVD][Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-update-kernel-ranchu-goldfish-5-4-5-10-gki-ramdisk-img-modules-rootavd-android-11-r-12-s-avd-google-play-store-api.4220697)

### rootAVD command line parameters
#### Linux
```
./rootAVD.sh ~/Android/Sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img
./rootAVD.sh EnvFixTask
./rootAVD.sh ~/Android/Sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img restore
./rootAVD.sh ~/Android/Sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img InstallKernelModules
```

#### MacOS
```
export PATH=$PATH:~/Library/Android/sdk/platform-tools
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img
./rootAVD.sh EnvFixTask
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img restore
./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img InstallKernelModules
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


### Options
* Install all APKs placed in the Apps folder
* If you set `PATCHFSTAB=true`
	* fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
	* !! a custom build Kernel is needed !!
* If you set `GetUSBHPmodZ=true`
	* The USB HOST Permissions Module Zip will be downloaded into `/sdcard/Download`

### Links
* [XDA [GUIDE] Build / Mod AVD Kernel Android 10 / 11 rootAVD [Magisk] [USB passthrough Linux] [Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-avd-kernel-android10-x86_64-29-root-magisk-usb-passthrough-linux.4212719)
* [Inject Android Hardware USB HOST Permissions](https://github.com/newbit1/usbhostpermissons)
* [XDA [SCRIPT] rootAVD - root your Android Studio Virtual Device emulator with Magisk [Android 11][Linux][Darwin/MacOS][WIN][Google Play Store APIs]](https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-11-linux-darwin-macos-win-google-play-store-apis.4218123)

### Magisk v22 Successfully tested with Stock Kernel on
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r02 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r02-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r01-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r02 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r02-windows.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r01-windows.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-S_r01.zip)
* [[Mar. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Mar. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-windows.zip)
* [[Mar. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r08 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-darwin.zip)
* [[Mar. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r08 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-windows.zip)

### Magisk v21.4 Successfully tested with Stock Kernel on
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-windows.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-linux.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis x86_64 r11 User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-29_r11.zip)
* [[Jan. 2021] - Android  7 (Nougat) API 24 Google Apis Play Store x86 r19 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-24_r19.zip)

### Change Logs
#### [Apr. 2021]
* [General] - Added "InstallKernelModules" update/install custom build kernel and modules
* [rootAVD.sh] - Added update_lib_modules function
* [General] - Added "restore" to put back your backup files
* [General] - Updated local Magisk App v22.1
* [rootAVD.sh] - Added Option to Download the USB HOST Permissions Module

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

### Credits
* [topjohnwu @ xda-developers](https://forum.xda-developers.com/m/topjohnwu.4470081)
* [topjohnwu Magisk File Host](https://github.com/topjohnwu/magisk-files)
* [topjohnwu Magisk App](https://github.com/topjohnwu/Magisk/releases)
* [topjohnwu Magisk v21.4](https://github.com/topjohnwu/Magisk/releases/tag/v21.4)
* [topjohnwu Magisk Manager v8.0.7](https://github.com/topjohnwu/Magisk/releases/tag/manager-v8.0.7)
* [shakalaca @ xda-developers](https://forum.xda-developers.com/m/shakalaca.1813976)
* [shakalaca MagiskOnEmulator](https://github.com/shakalaca/MagiskOnEmulator)
* [Akianonymus _json_value](https://gist.github.com/cjus/1047794#gistcomment-3313785)
