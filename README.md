# This Repo will be archived at the 24th of Oct 2023
# Due to the forced 2FA Mumbo Jumbo from GitHub,
# this Repo has moved to GitLab
# [rootAVD](https://gitlab.com/newbit/rootAVD)
### [newbit @ xda-developers](https://forum.xda-developers.com/m/newbit.1350876)
A Script to...
* root your Android Studio Virtual Device (AVD), with Magisk (Stable, Canary or Alpha)
* patch its fstab
* download and install the USB HOST Permissions Module for Magisk
* install custom build Kernel and its Modules
* download and install AOSP prebuilt Kernel and its Modules

...within seconds.

## Install Magisk
### Download rootAVD via
* [Click](https://github.com/newbit1/rootAVD/archive/refs/heads/master.zip)
* `git clone https://github.com/newbit1/rootAVD.git`

### Preconditions
* the AVD is running
* a working Internet connection for the Menu
* a command prompt / terminal is opened
* `adb shell` will connect to the running AVD
### Use Case Examples
#### on MacOS
<img src="https://github.com/newbit1/video-files/blob/master/rootAVD_MacOS.gif" width="50%" height="50%"/>

#### BlueStacks 4 on MacOS
<img src="https://github.com/newbit1/video-files/blob/master/rootAVD_MacOS_BlueStacks.gif" width="50%" height="50%"/>

#### on Windows
<img src="https://github.com/newbit1/video-files/blob/master/rootAVD_Windows.gif" width="50%" height="50%"/>

#### on Linux
<img src="https://github.com/newbit1/video-files/blob/master/rootAVD_Linux.gif" width="50%" height="50%"/>

#### Fake Boot.img on MacOS
<img src="https://github.com/newbit1/video-files/blob/master/rootAVD_MacOS_FAKEBOOTIMG.gif" width="50%" height="50%"/>

### How to Install ADB (Android SDK Platform-Tools)
* Open Android Studio -> SDK Manager -> Android SDK -> SDK Tools -> Check on **Android SDK Platform-Tools** -> Apply
<img src="https://user-images.githubusercontent.com/37043777/140064719-ea2dd704-1aea-4c38-9725-3edbdafe7924.png" width="200" height="200" />

## rootAVD Help Menu
```
rootAVD A Script to root AVD by NewBit XDA

Usage:  rootAVD [DIR/ramdisk.img] [OPTIONS] | [EXTRA ARGUMENTS]
or:     rootAVD [ARGUMENTS]

Arguments:
        ListAllAVDs                     Lists Command Examples for ALL installed AVDs

        InstallApps                     Just install all APKs placed in the Apps folder

Main operation mode:
        DIR                             a path to an AVD system-image
                                        - must always be the 1st Argument after rootAVD

ADB Path | Ramdisk DIR| ANDROID_HOME:
        [M]ac/Darwin:                   export PATH=~/Library/Android/sdk/platform-tools:$PATH
                                        export PATH=$ANDROID_HOME/platform-tools:$PATH
                                        system-images/android-$API/google_apis_playstore/x86_64/

        [L]inux:                        export PATH=~/Android/Sdk/platform-tools:$PATH
                                        export PATH=$ANDROID_HOME/platform-tools:$PATH
                                        system-images/android-$API/google_apis_playstore/x86_64/

        [W]indows:                      set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
                                        system-images\android-$API\google_apis_playstore\x86_64\

        ANDROID_HOME:                   By default, the script uses %LOCALAPPDATA%, to set its Android Home
                                        directory, search for AVD system-images and ADB binarys. This behaviour
                                        can be overwritten by setting the ANDROID_HOME variable.
                                        e.g. set ANDROID_HOME=%USERPROFILE%\Downloads\sdk

        $API:                           25,29,30,31,32,33,34,UpsideDownCake,etc.

Options:
        restore                         restore all existing .backup files, but doesn't delete them
                                        - the AVD doesn't need to be running
                                        - no other Argument after will be processed

        InstallKernelModules            install custom build kernel and its modules into ramdisk.img
                                        - kernel (bzImage) and its modules (initramfs.img) are inside rootAVD
                                        - both files will be deleted after installation

        InstallPrebuiltKernelModules    download and install an AOSP prebuilt kernel and its modules into ramdisk.img
                                        - similar to InstallKernelModules, but the AVD needs to be online

Options are exclusive, only one at the time will be processed.

Extra Arguments:
        DEBUG                           Debugging Mode, prevents rootAVD to pull back any patched file

        PATCHFSTAB                      fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
                                        - other entries can be added in the script as well
                                        - a custom build Kernel might be necessary

        GetUSBHPmodZ                    The USB HOST Permissions Module Zip will be downloaded into /sdcard/Download

        FAKEBOOTIMG                     Creates a fake Boot.img file that can directly be patched from the Magisk APP
                                        - Magisk will be launched to patch the fake Boot.img within 60s
                                        - the fake Boot.img will be placed under /sdcard/Download/fakeboot.img

Extra Arguments can be combined, there is no particular order.

Notes: rootAVD will
- always create .backup files of ramdisk*.img and kernel-ranchu
- replace both when done patching
- show a Menu, to choose the Magisk Version (Stable || Canary || Alpha), if the AVD is online
- make the choosen Magisk Version to its local
- install all APKs placed in the Apps folder
- use %LOCALAPPDATA%\Android\Sdk to search for AVD system images
```
### Linux & MacOS
```
Command Examples:
./rootAVD.sh
./rootAVD.sh ListAllAVDs
./rootAVD.sh InstallApps

./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img restore
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-33/google_apis_playstore/x86_64/ramdisk.img AddRCscripts
```

<details>
<summary>Command Examples: for ALL installed AVDs</summary>

```
./rootAVD.sh
./rootAVD.sh ListAllAVDs
./rootAVD.sh InstallApps

./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img restore
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-25/google_apis/armeabi-v7a/ramdisk.img AddRCscripts

./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img restore
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-25/google_apis/x86_64/ramdisk.img AddRCscripts

./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img restore
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-30/google_apis_playstore/x86/ramdisk.img AddRCscripts

./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img FAKEBOOTIMG
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img restore
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img InstallKernelModules
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk-qemu.img AddRCscripts

./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img restore
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-30/android-automotive-playstore/x86_64/ramdisk.img AddRCscripts

./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img FAKEBOOTIMG
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img restore
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img InstallKernelModules
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img InstallPrebuiltKernelModules
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
./rootAVD.sh system-images/android-29/android-automotive-playstore/x86/ramdisk.img AddRCscripts
```
</details>

### Windows
```
Command Examples:
rootAVD.bat
rootAVD.bat ListAllAVDs
rootAVD.bat InstallApps

rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img FAKEBOOTIMG
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img restore
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallKernelModules
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
```

<details>
<summary>Command Examples: for ALL installed AVDs</summary>

```
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img FAKEBOOTIMG
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img restore
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallKernelModules
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules
rootAVD.bat system-images\android-33\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG

rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img FAKEBOOTIMG
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img restore
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img InstallKernelModules
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules
rootAVD.bat system-images\android-25\google_apis_playstore\x86_64\ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG

rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img FAKEBOOTIMG
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img DEBUG PATCHFSTAB GetUSBHPmodZ
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img restore
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img InstallKernelModules
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img InstallPrebuiltKernelModules
rootAVD.bat system-images\android-25\google_apis_playstore\armeabi-v7a\ramdisk.img InstallPrebuiltKernelModules GetUSBHPmodZ PATCHFSTAB DEBUG
```
</details>

### Notes
* 64 Bit Only Systems needs Magisk 23.x
* In the Menu, you can choose between the newest Magisk, Canary, Stable and Alpha, Version.
* With the new Option `s`, you can see and download any other Versions of Magisk
* Once choosen, the script will make that Version to your local one.
* Prebuilt Kernel and Modules will be pulled from [AOSP](https://android.googlesource.com/kernel/prebuilts)
* Starting Magisk from Terminal via `adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1`
* API 28 (Pie) is **not supported** at all -> [because](https://source.android.com/devices/bootloader/partitions/system-as-root#sar-partitioning)
* Magisk Versions >= 26.x can only be proper installed with the FAKEBOOTIMG argument
	* due to the [New sepolicy.rule Implementation](https://github.com/topjohnwu/Magisk/releases/tag/v26.1)
* Android 14 needs Magisk Version >= 26.x to be rooted

### ANDROID_HOME
* Default location can be overwritten by setting the `ANDROID_HOME` variable
* In both cases, the script will search in it for AVD system-images and adb binarys
* `ANDROID_HOME` Sets the path to the SDK installation directory -> [AOSP Variables reference](https://developer.android.com/tools/variables#envar)

### Notes for Apk Developers
* [How-To SU](http://su.chainfire.eu) from [Chainfire's](https://github.com/Chainfire) [libsuperuser](https://github.com/Chainfire/libsuperuser) - Guidelines for problem-free su usage (for Android Developers)
* [TopJohnWu's libsu](https://github.com/topjohnwu/libsu) - An Android library providing a complete solution for apps using root permissions

### Fake Boot.img Function
* During runtime, the script will launch the Magisk APK so that you can patch the fake Boot.img within 60s
* The script also detects if there is already a patched Boot.img present
* This feature lets you also update and switch between Magisk Versions
	* Updating a patched ramdisk will delete the overlay.d folder, all mods are gone!
* If Magisk can't open a file manager, i.e. on Automotive AVDs,
	* download and install the famous [X-plore file manager](https://www.lonelycatgames.com/apps/xplore)
* The script switches to user 0, so that you can see `/sdcard/Download/fakeboot.img`

### 2 Ways to boot the AVD into Safe Mode
* 1st Way - If the AVD still boots normal:
	* Tap and Hold the **Power Button** until the 3 Options appear
	* Tap and Hold the **Power Off Button** until **Reboot to safe mode** appears
* 2nd Way - If the AVD stuck while booting (**black** screen):
	* Tap and Hold the **Volume Down Button**
	* The Time Window is between the **Launching Emulator Bar** is approx **half way** until the **Google Boot Screen** appears
* Confirmation
	* On the Bottom Left Corner reads: **Safe mode**

### Automotive Notes
* After patching the ramdisk.img and cycle power, switch to user 0 via `adb shell am switch-user 0`
	* open the Magisk App and the **Requires Additional Setup** pops up -> reboot AVD
	* switch again to user 0
		* open the Magisk App -> Settings -> Multiuser Mode -> **User-Independent** -> reboot AVD
* Every time you want to Grant Su Permissions, switch to user 0 and then back to 10 `adb shell am switch-user 10`
* Alternative, you can install the Module [Magisk Single User Mod](https://github.com/newbit1/msum)
	* and remove all user higher than 0 i.e. `adb shell pm remove-user 13` or `adb shell pm remove-user 10`

### BlueStacks 4 Notes on MacOs
* Modules are working
* Zygisk doesn't work
* The Home Screen Apk closes as soon as Magisk APP is installed
	* but you can start Magisk from Terminal via `adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1`
	* and Hide the Magisk APP to Settings i.e.
* ADB Connection is very buggy, `adb kill-server` is necessary quite often

### Links
* [XDA [GUIDE] Build / Mod AVD Kernel Android 10 / 11 rootAVD [Magisk] [USB passthrough Linux] [Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-avd-kernel-android10-x86_64-29-root-magisk-usb-passthrough-linux.4212719)
* [Inject Android Hardware USB HOST Permissions](https://github.com/newbit1/usbhostpermissons)
* [XDA [SCRIPT] rootAVD - root your Android Studio Virtual Device emulator with Magisk [Android 12][Linux][Darwin/MacOS][WIN][Google Play Store APIs]](https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-11-linux-darwin-macos-win-google-play-store-apis.4218123)
* [rootCROS - A Script to root your Google Chrome OS installed on a non Chromebook Device](https://github.com/newbit1/rootCROS)

### XDA [GUIDE] How to [Build|Mod|Update] a custom AVD Kernel and its Modules
* [[GUIDE][Build|Mod|Update][kernel-ranchu][goldfish][5.4][5.10][GKI][ramdisk.img][modules][rootAVD][Android 11(R) 12(S)][AVD][Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-update-kernel-ranchu-goldfish-5-4-5-10-gki-ramdisk-img-modules-rootavd-android-11-r-12-s-avd-google-play-store-api.4220697)

### How to root AVDs without Play Store (Google APIs) out of the box
### Windows
* open a terminal -> win + r `cmd`
	* add emulator to your PATH
	* find your AVD
	* launch your AVD with the `-writable-system` argument
	```
	set PATH=%LOCALAPPDATA%\Android\Sdk\emulator;%PATH%
	emulator -list-avds
		Pixel_4_API_29
	emulator -avd Pixel_4_API_29 -writable-system
	```
* open a 2nd terminal -> win + r `cmd`
	* enter the following commands one by one
	```
	set PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%
	adb root
	adb shell avbctl disable-verification
	adb disable-verity
	adb reboot
	adb root
	adb remount
	adb shell
	generic_x86_64:/ #
	```

### [Compatibility Chart](CompatibilityChart.md)
<details>
<summary>Archive</summary>
### Magisk v23.0 Alpha Successfully tested with Stock Kernel on
* [[Oct. 2021] - Android 12 (S) API 32 Google Apis Play Store x86_64 Sv2 r01 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-Sv2_r01-windows.zip)
* [[Oct. 2021] - Android 12 (S) API 32 Google Apis Play Store x86_64 Sv2 r01 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-Sv2_r01-darwin.zip)
* [[Oct. 2021] - Android 12 (S) API 31 Google Apis Play Store ARM 64 v8a r08 (M1) Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/arm64-v8a-31_r08-darwin.zip)
* [[Oct. 2021] - Android 11 (R) API 30 Google Apis Play Store ARM 64 v8a r10 (M1) Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/arm64-v8a-30_r10-darwin.zip)
* [[Oct. 2021] - Android 12 (S) API 31 Google Apis Play Store x86_64 r08 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-31_r08-darwin.zip)
* [[Oct. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-darwin.zip)
* [[Oct. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)

### Magisk v22.1+ Successfully tested with Stock Kernel on
* [[Oct. 2021] - Android  8 (Oreo) API 26 Google Apis Play Store x86 r07 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-26_r07.zip)
* [[Oct. 2021] - Android  7 (Nougat) API 24 Google Apis Play Store x86 r19 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-24_r19.zip)
* [[Oct. 2021] - Android  7 (Nougat) API 24 Google Apis x86_64 r27 Production Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-24_r27.zip)
* [[Oct. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-windows.zip)
* [[Oct. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86 r08 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-29_r08-windows.zip)
* [[Oct. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-darwin.zip)
* [[Oct. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86 r08 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-29_r08-darwin.zip)
* [[June 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r05 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r05-darwin.zip)
* [[Apr. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r04 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r04-darwin.zip)
* [[May. 2021] - Android Wear 8 (Oreo) API 26 Google Apis Play Store x86 r04 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/android-wear/x86-26_r04.zip)
* [[May. 2021] - Android TV 11 (R) API 30 Google Apis Play Store x86 r03 Windows Production Build](https://dl.google.com/android/repository/sys-img/android-tv/x86-30_r03.zip)
* [[May. 2021] - Android TV 10 (Q) API 29 Google Apis Play Store x86 r03 Windows Production Build](https://dl.google.com/android/repository/sys-img/android-tv/x86-29_r03.zip)
* [[May. 2021] - Android 10 (Q) API 29 Google Apis Play Store x86 r01 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/android-automotive/x86-29_r01.zip)
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

</details>

### Change Logs

#### [August 2023]

* [rootAVD.sh] - Added Pagesize Padding in the fakeboot.img
* [rootAVD.sh] - Updated the creation of the fakeboot.img
* [rootAVD.sh] - Added another way of checking the AVDs Internet connection

#### [July 2023]
* [rootAVD.bat] - Fixed file ListAllAVDs not found bug
* [rootAVD.bat] - Fixed some errors with double spaces
* [rootAVD.bat] - Added TestADBWORKDIR routine

#### [June 2023]
* [rootAVD.sh] - improved finding BusyBox routine, and once again
* [rootAVD.sh] - rewritten the file and folder handling entirely, Darwin and Linux
* [rootAVD.sh] - improved finding BusyBox routine, again
* [General] - Added `.gitattributes` with `*.sh text eol=lf` to force UNIX line ending on Windows
* [rootAVD.bat] - rewritten the file and folder handling entirely
* [rootAVD.bat] - fixed typos and bug fixes
* [rootAVD.bat] - updated the TestADB routine, adb path will now be set automatically
* [rootAVD.bat] - updated Exit calls
* [General] - updated the README.md

#### [May 2023]
* [rootAVD.sh] - removed Busybox from Script

#### [April 2023]
* [General] - added link to X-plore file manager
* [General] - added link to Magisk Single User Mod
* [General] - added switching to user 0 when running FAKEBOOTIMG
* [rootAVD.bat] - changed return 1 to return 0
* [rootAVD.sh] - changed return 1 to return 0
* [rootAVD.sh] - changed copy and move routine
* [rootAVD.sh] - added support for ramdisk-qemu.img

<details>
<summary>Archive</summary>

### Change Logs
#### [December 2022]
* [rootAVD.sh] - Fixed arithmetic syntax error in decompress_ramdisk
#### [November 2022]
* [General] - Bug fixes
* [General] - Updated to Magisk Stable Version 25.2
* [General] - Added FAKEBOOTIMG Use Case Examples as Gif
* [rootAVD.sh] - Added support for adding the stub.apk if present
* [General] - Added support for already patched ramdisk files
* [General] - removed the EnvFixTask Argument
* [General] - Bug fixes
* [rootAVD.sh] - Added FAKEBOOTIMG Argument that creates a fake Boot.img which can be patched directed from the Magisk APK
#### [March 2022]
* [rootAVD.sh] - Added toggleRamdisk Argument that toggles between patched and stock ramdisk
* [rootAVD.sh] - Changed the need of a Magisk.zip file
* [General] - Added Use Case Examples as Gif
* [General] - Added Option to Download older Magisk Versions
* [rootAVD.sh] - Added BlueStacks 4 Support on MacOS
* [General] - Bug fixes
#### [February 2022]
* [General] - Updated to Magisk Stable Version 24.1
#### [October 2021]
* [rootAVD.sh] - Added get Up-To-Date Script Routine if Script is broken
* [rootAVD.sh] - Updated LZ4 decompression Routine
* [rootAVD.sh] - Updated InstallPrebuiltKernelModules Routine to support ARM64 Kernels
* [rootAVD.sh] - Updated Busybox Extraction Routine
* [General] - Added Multiarch Busybox Binarys and 64-Bit Only Support
* [General] - Added Alpha Channel to the Menu
* [rootAVD.bat] - Added Shut Down Feature
* [rootAVD.sh] - Added Shut Down Feature
* [General] - Added Android 12 (S) API 31 Status
* [General] - Added Link to Android AppSecs Video about rootAVD
#### [July 2021]
* [rootAVD.bat] - Changed TestADB
* [General] - Added rootCROS Project to Links
#### [June 2021]
* [General] - Android 12 (S) r05
#### [May 2021]
* [General] - Updated to Magisk App v23.0
* [rootAVD.sh] - Added "AddRCscripts" Argument that **install all custom *.rc scripts, placed in the rootAVD folder, into ramdisk.img/overlay.d/sbin**
* [rootAVD.sh] - Added BusyBox Binary after the rootAVD script
* [rootAVD.bat] - Added ListAllAVDs and InstallApps as Arguments
* [rootAVD.sh] - Added "ListAllAVDs" Argument that **Lists Command Examples for ALL installed AVDs**
* [rootAVD.sh] - Added "InstallApps" Argument to **Just install all APKs placed in the Apps folder**
* [rootAVD.bat] - Added comprehensive Help Menu
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
* [topjohnwu Magisk](https://github.com/topjohnwu/Magisk)
* [Magisk-Modules-Repo](https://github.com/Magisk-Modules-Repo)
* [shakalaca @ xda-developers](https://forum.xda-developers.com/m/shakalaca.1813976)
* [shakalaca MagiskOnEmulator](https://github.com/shakalaca/MagiskOnEmulator)
* [huskydg @ xda-developers](https://forum.xda-developers.com/m/huskydg.11455139)
* [huskydg MagiskOnEmu](https://github.com/HuskyDG/MagiskOnEmu)
* [Akianonymus _json_value](https://gist.github.com/cjus/1047794#gistcomment-3313785)
* [Tad Fisher Android Nixpkgs](https://github.com/tadfisher/android-nixpkgs)
* [Sébastien Corne magisk-single-user](https://github.com/seebz)
* [remote-android Native Bridge Support in ReDroid](https://github.com/remote-android/redroid-doc/tree/master/native_bridge)
* [vvb2060 Magisk Alpha](https://github.com/vvb2060/magisk_files/)
* [All-in-one Markdown editor by terrylinooo](https://markdown-editor.github.io/)
* [Online Free WYSIWYG HTML Editor](https://www.htmeditor.com/author/)
* [HTML Tidy - Online Markup Corrector](https://htmltidy.net)
* [ffmpeg + ImageMagick. Convert video to GIF by using Terminal.app in macOS](https://acronis.design/ffmpeg-imagemagick-convert-video-to-gif-using-the-terminal-app-in-macos-657948adf900)
* [Kazam Screencaster](https://launchpad.net/kazam)

