# rootAVD
### [newbit @ xda-developers](https://forum.xda-developers.com/m/newbit.1350876/)
A Script to root your Android Studio Virtual Device (AVD),
with Magisk and Magisk Manager within seconds

### How To Use it with Magisk v21.4
* rootAVD needs a path with file to an AVD ramdisk
* rootAVD will backup your ramdisk.img and replace it when done patching

### How To Use it under Android S with Magisk v22
* rootAVD needs to run twice
* 1st - to patch the ramdisk.img
* 2nd - after rebooting the AVD
	* The "Additional Setup Required" will not be triggered in Android S by Magisk App in AVD,
	* this must be done manually on the 2nd run
	* Grant Shell Su Permissions will pop up a few times
	* rootAVD will reboot the AVD automatically
	* check Magisk App !!

#### Linux
`./rootAVD.sh ~/Android/Sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img`

#### MacOS
`./rootAVD.sh ~/Library/Android/sdk/system-images/android-S/google_apis_playstore/x86_64/ramdisk.img`

#### Windows
`rootAVD.bat %LOCALAPPDATA%\Android\Sdk\system-images\android-30\google_apis_playstore\x86_64\ramdisk.img`

### Notes
* adb must be in your `$PATH`

### Options
* Install all APKs placed in the Apps folder
* If you set `PATCHFSTAB=true`
	* fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
	* !! a custom build Kernel is needed !!

### Links
* [XDA [GUIDE] Build / Mod [Kernel 5.4][GKI][Android 11 (R)][kernel-ranchu][goldfish][AVD][Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-kernel-5-4-gki-android-11-r-kernel-ranchu-goldfish-avd-google-play-store-api.4220697)
* [XDA [GUIDE] Build / Mod AVD Kernel Android 10 / 11 rootAVD [Magisk] [USB passthrough Linux] [Google Play Store API]](https://forum.xda-developers.com/t/guide-build-mod-avd-kernel-android10-x86_64-29-root-magisk-usb-passthrough-linux.4212719)
* [Inject Android Hardware USB HOST Permissions](https://github.com/newbit1/usbhostpermissons)
* [XDA [SCRIPT] rootAVD - root your Android Studio Virtual Device emulator with Magisk [Android 11][Linux][Darwin/MacOS][WIN][Google Play Store APIs]](https://forum.xda-developers.com/t/script-rootavd-root-your-android-studio-virtual-device-emulator-with-magisk-android-11-linux-darwin-macos-win-google-play-store-apis.4218123)

### Magisk v22 Successfully tested with Stock Kernel on
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-S_r01-darwin.zip)
* [[Mar. 2021] - Android 12 (S) API 30 Google Apis Play Store x86_64 r01 Darwin/MacOS User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-S_r01.zip)
* [[Mar. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Mar. 2021] - Android 10 (R) API 29 Google Apis Play Store x86_64 r08 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-darwin.zip)

### Magisk v21.4 Successfully tested with Stock Kernel on
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Darwin/MacOS Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-darwin.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Windows Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-windows.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-linux.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis x86_64 r11 User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-29_r11.zip)
* [[Jan. 2021] - Android  7 (Nougat) API 24 Google Apis Play Store x86 r19 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-24_r19.zip)

### Change Logs
#### [Mar. 2021]
* [General] - Updated to Magisk App v22.0
* [General] - Fixed some bugs and typos
* [rootAVD.sh] - Added Compression Detection for LZ4 and GZ
* [rootAVD.sh] - Updated shakalaca's Ramdisk Repack Routine
* [rootAVD.sh] - Added "Additional Setup Required" manually for Android S

### Credits
* [topjohnwu @ xda-developers](https://forum.xda-developers.com/m/topjohnwu.4470081)
* [topjohnwu Magisk App v22.0](https://github.com/topjohnwu/Magisk/releases/tag/v22.0)
* [topjohnwu Magisk v21.4](https://github.com/topjohnwu/Magisk/releases/tag/v21.4)
* [topjohnwu Magisk Manager v8.0.7](https://github.com/topjohnwu/Magisk/releases/tag/manager-v8.0.7)
* [shakalaca @ xda-developers](https://forum.xda-developers.com/m/shakalaca.1813976)
* [shakalaca MagiskOnEmulator](https://github.com/shakalaca/MagiskOnEmulator)
