#!/bin/bash
##########################################################################################
#
# Magisk Boot Image Patcher - original created by topjohnwu and modded by shakalaca's
# modded by NewBit XDA for Android Studio AVD
# Successfully tested on Android API:
# [Dec. 2019] - 29 Google Apis Play Store x86_64 Production Build
# [Jan. 2021] - 30 Google Apis Play Store x86_64 Production Build
#
##########################################################################################

# While debugging and developing you can turn this flag on
DEBUG=false
#DEBUG=true
# Shows whatever line get executed...
if ("$DEBUG"); then
	set -x
fi

# Copied 1 to 1 from topjohnwu
getdir() {
  case "$1" in
    */*) dir=${1%/*}; [ -z $dir ] && echo "/" || echo $dir ;;
    *) echo "." ;;
  esac
}

checkfile() {
	if [ -r "$1" ]; then 
		#echo "File exists and is readable"
		if [ -s "$1" ]; then 
			#echo "and has a size greater than zero"
			if [ -w "$1" ]; then 
				#echo "and is writable"
				if [ -f "$1" ]; then 
					#echo "and is a regular file."
					return 1			
				fi
			fi
		fi
	fi
	return 0
}

# If all is done well so far, you can install some APK's to the AVD
# every APK file in the Apps DIR will be (re)installed
# Like magisk.apk etc.
installapps() {
  	APPS="Apps/*"
	echo "[-] Install all APKs placed in the Apps folder"
	FILES=$APPS
	FILENAME=
	for f in $FILES
	do
		echo "[*] Trying to install $f"
		adb install -r "$f"
	done
}

CopyMagiskToAVD() {
	# If there is no file to work with, abort the script
	if (checkfile "$1" -eq 0); then
	  echo "rootAVD needs a path with file to an AVD ramdisk"
	  echo "rootAVD will backup your ramdisk.img and replace it when finished"
	  echo "./rootAVD.sh ~/Android/Sdk/system-images/android-30/google_apis_playstore/x86_64/ramdisk.img"
	  exit 0
	fi

	echo "[-] Test if ADB SHELL is working"
	ADBWORKS=$(adb shell 'echo true' 2>/dev/null) 
	if (! "$ADBWORKS"); then
		echo "no ADB connectoin possible"
		exit 0
	fi

	# Set Folders and FileNames
	echo "[*] Set Directorys"
	PATHWITHFILE="$1"
	PATHTOFILE=${PATHWITHFILE%/*}
	FILE=${PATHWITHFILE##*/}
	fileIsKernel=false
	fileIsRamdisk=false
	BACKUPFILE=$FILE".backup"
	# The Folder where the script was called from
	ROOTAVD="`getdir "${BASH_SOURCE:-$0}"`"
	MAGISKZIP=$ROOTAVD/Magisk.zip
	
	# change to ROOTAVD directory
	cd $ROOTAVD

	# Is it a ramdisk named file?
	if [ $FILE != "ramdisk.img" ]; then
		echo "[!] please give a path to a ramdisk file"    
		exit 0
	fi

	# If no backup file exist, create one
	if (checkfile $PATHTOFILE/$BACKUPFILE -eq 0); then
		echo "[*] create Backup File"
		cp $PATHWITHFILE $PATHTOFILE/$BACKUPFILE
	else
		echo "[-] Backup exists already"
	fi

	# Download the Magisk zip file -> Magisk-v21.2
	MAGISKZIPDL=https://github.com/topjohnwu/Magisk/releases/download/v21.2/Magisk-v21.2.zip
	# If Magisk.zip file already exist, don't download it again
	if (checkfile $MAGISKZIP -eq 0); then	
		echo "[*] Downloading Magisk installer Zip"
		wget $MAGISKZIPDL -O $MAGISKZIP > /dev/null 2>&1
	else
		echo "[-] Magisk installer Zip exists already"
	fi
	echo "[*] Just in case, cleaning up the Magisk DIR"
	rm -rf $ROOTAVD/Magisk

	echo "[*] unpacking Magisk installer Zip"
	unzip $MAGISKZIP -d Magisk > /dev/null 2>&1
	
	echo "[-] In any AVD via ADB, you can execute code without root in /data/data/com.android.shell "
	ADBWORKDIR=/data/data/com.android.shell
	
	echo "[*] Copy the original AVD ramdisk.img into Magisk DIR"
	cp $PATHWITHFILE $ROOTAVD/Magisk

	echo "[-] Copy Magisk Installer into Magisk DIR"
	cp rootAVD.sh $ROOTAVD/Magisk

	echo "[*] Just in case, cleaning up the ADB working space"
	adb shell rm -rf $ADBWORKDIR/Magisk

	echo "[-] Pushing all the stuff into the ADB working DIR"
	ADBPUSHECHO=$(adb push $ROOTAVD/Magisk $ADBWORKDIR 2>/dev/null) 
	echo "[*] $ADBPUSHECHO"

	echo "[-] run the actually Boot/Ramdisk/Kernel Image Patch Script"
	echo "[*] from Magisk by topjohnwu and modded by NewBit XDA"
	adb shell sh $ADBWORKDIR/Magisk/rootAVD.sh "ranchu"

	# In Debug-Mode we can skip parts of the script
	if (! "$DEBUG"); then

		echo "[-] After the ramdisk.img file is patched and back gz'ed,"
		echo "[*] pull it back in the Magisk DIR"
		adb pull $ADBWORKDIR/Magisk/ramdiskpatched4AVD.img

		echo "[-] Clean up the ADB working space"
		adb shell rm -rf $ADBWORKDIR/Magisk
		rm -rf $ROOTAVD/Magisk
		
		echo "[*] Move and rename the patched ramdisk.img to the original AVD DIR"
		mv ramdiskpatched4AVD.img $PATHWITHFILE
		
		installapps

		echo "[-] reboot the AVD and see if it worked"
		echo "[-] Root and Su with Magisk for Android Studio AVDs"
		echo "[-] Modded by NewBit XDA - Jan. 2021"
		echo "[!] Huge Credits and big Thanks to topjohnwu and shakalaca"

	fi
}

InstallMagiskToAVD() {
	echo "[-] Switch to the location of the script file"
	BASEDIR="`getdir "${BASH_SOURCE:-$0}"`"
	TMPDIR=$BASEDIR/tmp
	UB=$BASEDIR/META-INF/com/google/android/update-binary
	BB=$BASEDIR/busybox
	RDF=$BASEDIR/ramdisk.img

	# change to base directory
	cd $BASEDIR

	chmod -R 755 .

	# prepare busybox
	echo "[*] Extracting busybox ..."
	sh $UB -x > /dev/null 2>&1

	# rename ramdisk.img to ramdisk.img.gz
	mv $RDF $RDF".gz"

	# Detect version and architecture
	# To select the right files for the patching
	API=$(getprop ro.build.version.sdk)
	ABI=$(getprop ro.product.cpu.abi)
	ABI2=$(getprop ro.product.cpu.abi2)
	ABILONG=$(getprop ro.product.cpu.abi)
	ARCH=arm
	ARCH32=arm
	IS64BIT=false
	if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
	if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
	if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
	if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;

	echo "[-] Device Platform: $ARCH"
	echo "[-] Device API: $API"
	echo "[-] ARCH32 $ARCH32"


	# There is only a x86 or arm DIR with binaries
	BINDIR=$ARCH32

	echo "[*] copy all files from BINDIR to BASEDIR"
	cp $BINDIR/* $BASEDIR
	chmod -R 755 .

	# In that DIR with all the binaries is also the x64 version of it
	# Rename it if it is a 64-Bit AVD version
	$IS64BIT && mv -f magiskinit64 magiskinit 2>/dev/null || rm -f magiskinit64

	# On Android 7 with KEEPFORCEENCRYPT=false,
	# AVD doesn't boot

	KEEPFORCEENCRYPT=$(getprop ro.kernel.qemu.encrypt)

	if [ ! -z $KEEPFORCEENCRYPT ]; then
		KEEPFORCEENCRYPT=true
	else
		KEEPFORCEENCRYPT=false
	fi

	#KEEPFORCEENCRYPT=false

	# On Android 7 with KEEPVERITY=false,
	# ./magiskboot cpio ramdisk.cpio patch will cause segmentation fault
	if [ "$API" -le "24" ] || [ "$API" -le "28" ] || [ "$API" -le "26" ]|| [ "$API" -le "30" ]; then KEEPVERITY=true; fi;
	KEEPVERITY=false
	[ -z $RECOVERYMODE ] && RECOVERYMODE=false

	export KEEPVERITY
	export KEEPFORCEENCRYPT

	# Extract magisk if doesn't exist
	[ -e magisk ] || ./magiskinit -x magisk magisk

	echo "[-] taken from shakalaca's MagiskOnEmulator/process.sh"
	echo "[*] executing ramdisk splitting / extraction / repacking "
	# extract and check ramdisk

	if [[ $API -ge 30 ]]; then
		$BB gzip -fdk ${RDF}.gz
		echo "[-] API level greater then 30"
		echo "[*] Check if we need to repack ramdisk before patching .."
		COUNT=`$BB strings -t d $RDF | $BB grep 00TRAILER\!\!\! | $BB wc -l`

	  if [[ $COUNT -gt 1 ]]; then
		echo "[-] Multiple cpio archives detected"
		REPACKRAMDISK=1
	  fi
	fi

	if [[ -n $REPACKRAMDISK ]]; then
		rm ${RDF}.gz
	  echo "[*] Unpacking ramdisk .."
	  mkdir -p $TMPDIR/ramdisk
	  LASTINDEX=0
	  IBS=1
	  OBS=4096

	  RAMDISKS=`$BB strings -t d $RDF | $BB grep 00TRAILER\!\!\!`
	  for OFFSET in $RAMDISKS
	  do
		# calculate offset to next archive
		if [[ $OFFSET == *"TRAILER"* ]]; then
		  # find position of end of TRAILER!!! string in image
		  LEN=${#OFFSET}
		  START=$((LASTINDEX+LEN))

		  # find first occurance of string in image, that will be start of cpio archive
		  dd if=$RDF skip=$START count=$OBS ibs=$IBS obs=$OBS of=$TMPDIR/temp.img > /dev/null 2>&1
		  HEAD=(`$BB strings -t d $TMPDIR/temp.img | $BB head -1`)
		  
		  # wola
		  LASTINDEX=$((START+HEAD[0]))
		  #echo "LASTINDEX="$LASTINDEX
		  continue
		fi

		# number of blocks we'll extract
		BLOCKS=$(((OFFSET+128)/IBS))
		
		# extract and dump
		echo "[-] Dumping from $LASTINDEX to $BLOCKS .."
		dd if=$RDF skip=$LASTINDEX count=$BLOCKS ibs=$IBS obs=$OBS of=$TMPDIR/temp.img > /dev/null 2>&1
		cd $TMPDIR/ramdisk > /dev/null
		  cat $TMPDIR/temp.img | $BASEDIR/busybox cpio -i > /dev/null 2>&1
		cd - > /dev/null
		LASTINDEX=$OFFSET
	  done

		echo "[*] Repacking ramdisk .."
		cd $TMPDIR/ramdisk > /dev/null
		$BB find . | $BB cpio -H newc -o > $RDF
		cd - > /dev/null

		rm $TMPDIR/temp.img
	else
		echo "[*] After decompressing ramdisk.img, magiskboot will work"
		./magiskboot decompress $RDF".gz"
	fi

	mv $RDF "ramdisk.cpio"

	echo "[-] Test patch status and do restore"
	echo "[-] Checking ramdisk status"

	if [ -e ramdisk.cpio ]; then
		./magiskboot cpio ramdisk.cpio test 2>/dev/null
		STATUS=$?
		echo "[-] STATUS=$STATUS"
	else
		echo "[-] Stock A only system-as-root"
		STATUS=0
	fi

	case $((STATUS & 3)) in
	  0 )  # Stock boot
		echo "[-] Stock boot image detected"
		SHA1=`./magiskboot sha1 ramdisk.cpio 2>/dev/null`
		cp -af ramdisk.cpio ramdisk.cpio.orig 2>/dev/null
		;;

	  1 )  # Magisk patched
		echo "[-] Magisk patched boot image detected"
		# Find SHA1 of stock boot image
		[ -z $SHA1 ] && SHA1=`./magiskboot cpio ramdisk.cpio sha1 2>/dev/null`
		./magiskboot cpio ramdisk.cpio restore
		cp -af ramdisk.cpio ramdisk.cpio.orig
		;;
	  2 )  # Unsupported
		echo "[!] Boot image patched by unsupported programs"
		echo "[!] Please restore back to stock boot image"
		;;
	esac

	if [ $((STATUS & 8)) -ne 0 ]; then
	  echo "[!] TWOSTAGE INIT image detected - Possibly using 2SI, export env var"
	  export TWOSTAGEINIT=true
	fi

	##########################################################################################
	# Ramdisk patches
	##########################################################################################

	echo "[-] Patching ramdisk"

	echo "KEEPVERITY=$KEEPVERITY" > config
	echo "KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT" >> config
	echo "RECOVERYMODE=$RECOVERYMODE" >> config
	# actually here is the SHA of the bootimage generated
	# we only have one file, so it could make sense
	[ ! -z $SHA1 ] && echo "SHA1=$SHA1" >> config

	# Here gets the ramdisk.img patched with the magisk su files and stuff

	# Set PATCHFSTAB=true if you want the RAMDISK merge your modded fstab.ranchu before Magisk Mirror gets mounted

	PATCHFSTAB=false
	PATCHFSTAB=true

	# cp the read-only fstab.ranchu from vendor partition and add usb:auto for SD devices
	# kernel musst have Mass-Storage + SCSI Support enabled to create /dev/block/sd* nodes

	echo "[!] PATCHFSTAB=$PATCHFSTAB"
	if ("$PATCHFSTAB"); then
		echo "[-] pulling fstab.ranchu from AVD"
		cp /system/vendor/etc/fstab.ranchu $(pwd)
		echo "[-] adding usb:auto to fstab.ranchu"
		echo "/devices/*/block/sd* auto auto defaults voldmanaged=usb:auto" >> fstab.ranchu
		# cat fstab.ranchu
		echo "[-] adding overlay.d folder to ramdisk"
		./magiskboot cpio ramdisk.cpio \
		"mkdir 750 overlay.d" \
		"mkdir 755 overlay.d/vendor" \
		"mkdir 755 overlay.d/vendor/etc" \
		"add 644 overlay.d/vendor/etc/fstab.ranchu fstab.ranchu"
		echo "[-] overlay adding complete"
		echo "[-] jumping back to patching ramdisk for magisk init"
	else
		echo "[!] Skipping fstab.ranchu patch with /dev/block/sda"
		echo "[?] If you want fstab.ranchu patched, set PATCHFSTAB=true"
	fi

	echo "[!] patching the ramdisk with Magisk Init"
	./magiskboot cpio ramdisk.cpio \
	"add 750 init magiskinit" \
	"patch" \
	"backup ramdisk.cpio.orig" \
	"mkdir 000 .backup" \
	"add 000 .backup/.magisk config"

	if [ $((STATUS & 4)) -ne 0 ]; then
		echo "[!] Compressing ramdisk before zipping it"
	  ./magiskboot cpio ramdisk.cpio compress
	fi

	# Perhaps it is not necessary to delete it
	#rm -f ramdisk.cpio.orig config
	echo "[*] zipping ramdisk"
	# Rename and compress ramdisk.cpio back to ramdiskpatched4AVD.img
	./magiskboot compress "ramdisk.cpio"
	mv "ramdisk.cpio.gz" "ramdiskpatched4AVD.img"
	return 0
}

# Script Entry Point
# Checking in which shell we are
SHELL=$(getprop ro.kernel.androidboot.hardware 2>/dev/null)
if [[ $SHELL == "ranchu" ]]; then
	if [[ $SHELL == $1 ]]; then
		echo "[!] We are in a emulator shell"
		InstallMagiskToAVD
	fi		
else
	echo "[!] We are in a bash shell"
	CopyMagiskToAVD $1
fi
exit 0
