#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2024 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

#save script path and change to it
STARTPATH=$(dirname "$(realpath "$0")")
cd "$STARTPATH" || exit 1

#get config
source config || { echo "config not found"; exit 1; }

#redefine TMPDIR to make it absolute
TMPDIR="$STARTPATH/$TMPDIR"

echo "Building for $ARCH"

function check_deps() {
  echo "Checking dependencies"
  for DEP in wget tar gzip cpio dd losetup sfdisk mkfs.vfat mkfs.ext4 sudo install sed patch
  do
    if ! command -v "$DEP" > /dev/null
    then
      echo "Tool $DEP not found"
      exit 1
    fi
  done
}

umount_retry() {
  if ! sudo umount "$1"
  then
    echo "Retrying in 2s"
    sleep 2
    sudo umount "$1" || return 1
  fi
  return 0
}

install_tmp() {
  if [ ! -f "$TMPDIR/.mympdos-tmp" ]
  then
    install -d "$TMPDIR"
    touch "$TMPDIR/.mympdos-tmp"
  fi
  cd "$TMPDIR" || exit 1
}

build_stage1() {
  echo "myMPDos build stage 1: Download"
  install_tmp
  if [ ! -f "$TMPDIR/$NETBOOT_ARCHIVE" ]
  then
    echo "Getting $NETBOOT_ARCHIVE"
    wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$NETBOOT_ARCHIVE" \
      -O "$TMPDIR/$NETBOOT_ARCHIVE"
  fi
  if [ ! -d "$TMPDIR/netboot" ]
  then
    install -d "$TMPDIR/netboot"
    if ! tar -xzf "$TMPDIR/$NETBOOT_ARCHIVE" -C "$TMPDIR/netboot"
    then
      echo "Can not extract $NETBOOT_ARCHIVE"
      rm -f "$NETBOOT_ARCHIVE"
      exit 1
    fi
  fi

  if [ ! -f "$TMPDIR/$ARCHIVE" ]
  then
    echo "Getting $ARCHIVE"
    wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$ARCHIVE" \
      -O "$TMPDIR/$ARCHIVE"
    if ! tar -tzf "$TMPDIR/$ARCHIVE" > /dev/null
    then
      echo "Can not extract $ARCHIVE"
      rm -f "$ARCHIVE"
      exit 1
    fi
  fi
}

build_stage2() {
  echo "myMPDos build stage 2: Create build image"
  install_tmp
  dd if=/dev/zero of="$TMPDIR/$BUILDIMAGE" bs=1M count="$IMAGESIZEBUILD"
  sfdisk "$TMPDIR/$BUILDIMAGE" <<< "1, ${BOOTPARTSIZEBUILD}, b, *"
  sfdisk -a "$TMPDIR/$BUILDIMAGE" <<< ","

  LOOP=$(sudo losetup --partscan --show -f "$BUILDIMAGE")
  [ "$LOOP" = "" ] && exit 1
  sudo mkfs.vfat "${LOOP}p1"
  sudo mkfs.ext4 "${LOOP}p2"
  install -d "$TMPDIR/mnt"
  sudo mount -ouid="$BUILDUSER" "${LOOP}p1" "$TMPDIR/mnt" || exit 1
  if ! tar -xzf "$TMPDIR/$ARCHIVE" -C "$TMPDIR/mnt"
  then
    echo "Extracting $TMPDIR/$ARCHIVE failed"
    exit 1
  fi
  cp "$TMPDIR/netboot/boot/$MODLOOP" "$TMPDIR/mnt/boot"

  echo "Copy build scripts"
  install -d "$TMPDIR/mnt/mympdos"
  find "$TMPDIR/mnt/mympdos/" -name \*~ -delete
  cp -r "$STARTPATH"/mympdos/build/* "$TMPDIR/mnt/mympdos"

  echo "Copy existing packages"
  install -d "$TMPDIR/mnt/mympdos-apks"
  if [ -f "$STARTPATH/repository/$ARCH/APKINDEX.tar.gz" ]
  then
    cp "$STARTPATH/repository/$ARCH/"*.apk "$TMPDIR/mnt/mympdos-apks/"
    cp "$STARTPATH/repository/$ARCH/APKINDEX.tar.gz" "$TMPDIR/mnt/mympdos-apks/"
  else
    echo "No existing packages found"
  fi
  if [ -f "$STARTPATH/keys/abuild.tgz" ]
  then
    echo "Using keys for public repository"
    cp "$STARTPATH/keys/abuild.tgz" "$TMPDIR/mnt/mympdos/"
  elif [ -f "$STARTPATH/apks/abuild.tgz" ]
  then
    echo "Using private build keys"
    cp "$STARTPATH/apks/abuild.tgz" "$TMPDIR/mnt/mympdos/"
  else
    echo "No saved abuild.tgz found"
  fi
  date +%s > "$TMPDIR/mnt/date"
  umount_retry "$TMPDIR/mnt" || exit 1
  sudo losetup -d "${LOOP}"

  echo "Patching initramfs"
  cd "$TMPDIR/netboot" || exit 1
  #rm -f "init"
  #gzip -dc "boot/$INITRAMFS" | cpio -id init
  if ! cp "$STARTPATH/mympdos/netboot/init.mympd" init
  then
    echo "Patching netboot init failed"
    exit 1
  fi
  echo ./init | cpio -H newc -o | gzip >> "$TMPDIR/netboot/boot/$INITRAMFS"
}

build_stage3() {
  echo "myMPDos build stage 3: Starting build"
  install_tmp
  $QEMU \
    -M virt -m "$BUILDRAM" -cpu "$CPU" -smp "$BUILDCPUS" \
    -kernel "$TMPDIR/netboot/boot/$KERNEL" -initrd "$TMPDIR/netboot/boot/$INITRAMFS" \
    -append "console=ttyAMA0 ip=dhcp" \
    -nographic \
    -drive "file=$TMPDIR/${BUILDIMAGE},format=raw" \
    -nic user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9
}

build_stage4() {
  echo "myMPDos build stage 4: Saving packages"
  install_tmp
  if [ -d "$STARTPATH/apks" ]
  then
    BACKUPDATE=$(stat -c"%Y" "$STARTPATH/apks")
    BACKUPDIR="$STARTPATH"/apks.$(date -d@"$BACKUPDATE" +%Y%m%d_%H%M)
    mv "$STARTPATH/apks" "$BACKUPDIR"
  fi
  install -d "$STARTPATH/apks/$ARCH"
  LOOP=$(sudo losetup --partscan --show -f "$TMPDIR/$BUILDIMAGE")
  sudo mount -text4 "${LOOP}p2" "$TMPDIR/mnt" || exit 1
  if [ -f "$TMPDIR/mnt/build/abuild.tgz" ]
  then
    cp "$TMPDIR/mnt/build/abuild.tgz" "$STARTPATH/apks/"
  else
    echo "No abuild.tgz found"
  fi
  if [ -f "$TMPDIR/mnt/build/packages/package/${ARCH}/APKINDEX.tar.gz" ]
  then
    cp "$TMPDIR"/mnt/build/packages/package/"${ARCH}"/* "$STARTPATH/apks/$ARCH/"
    cp "$TMPDIR"/mnt/build/packages/package/"${ARCH}"/* "$STARTPATH/repository/$ARCH/"
  else
    echo "No APKINDEX.tar.gz found"
  fi
  umount_retry "$TMPDIR/mnt" || exit 1
  sudo losetup -d "${LOOP}"
}

build_stage5() {
  echo "myMPDos build stage 5: Create image"
  install_tmp
  dd if=/dev/zero of="$TMPDIR/$IMAGE" bs=1M count="$IMAGESIZE"
  sfdisk "$TMPDIR/$IMAGE" <<< "1, ${BOOTPARTSIZE}, b, *"

  LOOP=$(sudo losetup --partscan --show -f "$TMPDIR/$IMAGE")
  [ "$LOOP" = "" ] && exit 1
  sudo mkfs.vfat "${LOOP}p1"
  install -d "$TMPDIR/mnt"
  sudo mount -ouid="$BUILDUSER" "${LOOP}p1" "$TMPDIR/mnt" || exit 1
  if ! tar -xzf "$ARCHIVE" -C "$TMPDIR/mnt"
  then
    echo "Extracting $ARCHIVE failed"
    exit 1
  fi
  cd "$STARTPATH/mympdos/overlay" || exit 1
  if ! tar -czf "$TMPDIR/mnt/mympdos-bootstrap.apkovl.tar.gz" .
  then
    echo "Creating overlay failed"
    exit 1
  fi
  cd "$TMPDIR" || exit 1
  if [ "$PRIVATEIMAGE" = "true" ]
  then
    echo "Copy private bootstrap.txt"
    cp "$STARTPATH/mympdos/bootstrap.txt" "$TMPDIR/mnt/"
  else
    echo "Copy sample bootstrap.txt files"
    cp "$STARTPATH"/mympdos/bootstrap-*.txt "$TMPDIR/mnt/"
  fi
  echo "Copy mpd.conf configurations"
  [ -f "$STARTPATH/mympdos/mpd.replace" ] && cp "$STARTPATH/mympdos/mpd.replace" "$TMPDIR/mnt/"
  [ -f "$STARTPATH/mympdos/mpd.conf" ] && cp "$STARTPATH/mympdos/mpd.conf" "$TMPDIR/mnt/"
  echo "Copy usercfg.txt"
  cp "$STARTPATH/mympdos/usercfg.txt" "$TMPDIR/mnt/"
  echo "Setting version to $VERSION"
  echo "$VERSION" > "$TMPDIR/mnt/myMPDos.version"

  install -d "$TMPDIR/mnt/mympdos-apk-keys/"
  echo "Copy local archive signing public key"
  tar --wildcards --strip-components=1 -xzf "$STARTPATH/apks/abuild.tgz" -C "$TMPDIR/mnt/mympdos-apk-keys/" ".abuild/*.rsa.pub"
  
  if [ -f "$STARTPATH/repository/mail@jcgames.de.rsa.pub" ] &&
     [ ! -f "$TMPDIR/mnt/mympdos-apk-keys/mail@jcgames.de.rsa.pub" ]
  then
    echo "Copy myMPDos archive signing public key"
    cp "$STARTPATH/repository/mail@jcgames.de.rsa.pub" "$TMPDIR/mnt/mympdos-apk-keys/"
  fi

  umount_retry mnt || exit 1
  sudo losetup -d "${LOOP}"
  install -d "$STARTPATH/images"
  mv "$TMPDIR/$IMAGE" "$STARTPATH/images"
  [ "$COMPRESSIMAGE" = "true" ] && gzip -9 "$STARTPATH/images/$IMAGE"

  echo ""
  echo "Image $STARTPATH/images/$IMAGE created successfully."
  if [ "$PRIVATEIMAGE" = "true" ]
  then
    echo ""
    echo "A productive bootstrap.txt was copied to the image."
    echo "Dont redistribute this image!"
    echo ""
  else
    echo ""
    echo "Next step is to burn the image to a sd-card and"
    echo "create the bootstrap.txt file."
    echo "There are samples in the image."
    echo ""
  fi
}

cleanup() {
  umountbuild
  echo "Removing tmp"
  [ -f "$TMPDIR/.mympdos-tmp" ] || exit 0
  rm -fr "$TMPDIR"
  echo "Removing old images"
  find "$STARTPATH/images" -name \*.img -mtime "$KEEPIMAGEDAYS" -delete
  find "$STARTPATH/images" -name \*.img.gz -mtime "$KEEPIMAGEDAYS" -delete
  echo "Removing old package directories"
  find "$STARTPATH" -maxdepth 1 -type d -name apks.\* -mtime "$KEEPPACKAGEDAYS" -exec rm -rf {} \;
}

umountbuild() {
  echo "Umounting build environment"
  install_tmp
  LOOPS=$(losetup | grep "myMPDos" | awk '{print $1}')
  for LOOP in $LOOPS
  do
    echo "Found dangling $LOOP"
    MOUNTS=$(mount | grep "$LOOP" | awk '{print $1}')
    for MOUNT in $MOUNTS
    do
      sudo umount "$MOUNT"
    done
  done
  LOOPS=$(losetup | grep "myMPDos" | awk '{print $1}')
  for LOOP in $LOOPS
  do
    sudo losetup -d "$LOOP"
  done
}

case "$2" in
  private|p)
    PRIVATEIMAGE="true";;
  *)
    PRIVATEIMAGE="false";;
esac

case "$1" in
  stage1|1)
    check_deps
    build_stage1
    ;;
  stage2|2)
    check_deps
    build_stage2
    ;;
  stage3|3)
    check_deps
    build_stage3
    ;;
  stage4|4)
    check_deps
    build_stage4
    ;;
  stage5|5)
    check_deps
    build_stage5
    ;;
  build|b)
    check_deps
    build_stage1
    build_stage2
    build_stage3
    build_stage4
    build_stage5
    ;;
  umountbuild|u)
    umountbuild
    ;;
  cleanup|c)
    cleanup
    ;;
  *)
    echo "Usage: $0 (b|1|2|3|4|5|c|u) [private|public]"
    echo ""
    echo "  build|b:        runs all stages"
    echo "  stage1|1:       downloads and extracts all needed sources"
    echo "  stage2|2:       creates the build image"
    echo "  stage3|3:       starts the build image"
    echo "  stage4|4:       copies the packages from build into apks"
    echo "  stage5|5:       creates the image"
    echo ""
    echo "  cleanup|c:      cleanup things"
    echo "  umountbuild|u:  removes dangling mounts and loop devices"
    echo ""
    echo "  private|p:      creates a image with a productive bootstrap.txt file"
    echo "  public:         creates a image with sample bootstrap.txt files (default)"
    ;;
esac

exit 0
