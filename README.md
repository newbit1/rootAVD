# rootAVD
### [newbit @ xda-developers](https://forum.xda-developers.com/m/newbit.1350876/)
a Script to root your Android Studio Virtual Device (AVD) with Magisk v21.2 and Magisk Manager v8.0.5

### Usage
rootAVD needs a path with file to an AVD ramdisk
./rootAVD.sh ~/Android/Sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img
rootAVD will backup your ramdisk.img and replace it when finished

### Options
* Install all APKs placed in the Apps folder
* If you set PATCHFSTAB=true
	* fstab.ranchu will get patched to automount Block Devices like /dev/block/sda1
	* !! a custom build Kernel is needed !!

### Links
* [XDA [GUIDE] Build / Mod AVD Kernel Android10 x86_64-29](https://forum.xda-developers.com/t/guide-build-mod-avd-kernel-android10-x86_64-29-root-magisk-usb-passthrough-linux.4212719/)
* [Inject Android Hardware USB HOST Permissions](https://github.com/newbit1/usbhostpermissons)

### Successfully tested with Stock Kernel on
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86_64 r10 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-30_r10-linux.zip)
* [[Jan. 2021] - Android 11 (R) API 30 Google Apis Play Store x86 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-30_r09-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis Play Store x86_64 r09 Linux Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86_64-29_r08-linux.zip)
* [[Dec. 2019] - Android 10 (Q) API 29 Google Apis x86_64 r11 User Debug Build](https://dl.google.com/android/repository/sys-img/google_apis/x86_64-29_r11.zip)
* [[Jan. 2021] - Android  7 (Nougat) API 24 Google Apis Play Store x86 r19 Production Build](https://dl.google.com/android/repository/sys-img/google_apis_playstore/x86-24_r19.zip)


### Credits
* [topjohnwu @ xda-developers](https://forum.xda-developers.com/m/topjohnwu.4470081)
* [topjohnwu Magisk v21.2](https://github.com/topjohnwu/Magisk/releases/tag/v21.2)
* [topjohnwu Magisk Manager v8.0.5](https://github.com/topjohnwu/Magisk/releases/tag/manager-v8.0.5)
* [shakalaca @ xda-developers](https://forum.xda-developers.com/m/shakalaca.1813976)
* [shakalaca MagiskOnEmulator](https://github.com/shakalaca/MagiskOnEmulator)





