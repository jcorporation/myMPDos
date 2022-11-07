#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2023 Juergen Mang <mail@jcgames.de>
# https://github.com/jcorporation/myMPDos
#

source config || { echo "config not found"; exit 1; }

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
  if [ ! -f .mympdos-tmp ]
  then
    install -d "$TMPDIR"
    cd "$TMPDIR" || exit 1
    touch .mympdos-tmp
  fi
}

build_stage1() {
  echo "myMPDos build stage 1: Download"
  if [ ! -f "$NETBOOT_ARCHIVE" ]
  then
    echo "Getting $NETBOOT_ARCHIVE"
    wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$NETBOOT_ARCHIVE" \
      -O "$NETBOOT_ARCHIVE"
  fi
  if [ ! -d netboot ]
  then
    install -d netboot
    if ! tar -xzf "$NETBOOT_ARCHIVE" -C netboot
    then
      echo "Can not extract $NETBOOT_ARCHIVE"
      exit 1
    fi
  fi

  if [ ! -f "$ARCHIVE" ]
  then
    echo "Getting $ARCHIVE"
    wget -q "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$ARCHIVE" \
      -O "$ARCHIVE"
    if ! tar -tzf "$ARCHIVE" > /dev/null
    then
      echo "Can not extract $ARCHIVE"
      exit 1
    fi
  fi
}

build_stage2() {
  echo "myMPDos build stage 2: Create build image"
  dd if=/dev/zero of="$BUILDIMAGE" bs=1M count="$IMAGESIZEBUILD"
  sfdisk "$BUILDIMAGE" <<< "1, ${BOOTPARTSIZEBUILD}, b, *"
  sfdisk -a "$BUILDIMAGE" <<< ","

  LOOP=$(sudo losetup --partscan --show -f "$BUILDIMAGE")
  [ "$LOOP" = "" ] && exit 1
  sudo mkfs.vfat "${LOOP}p1"
  sudo mkfs.ext4 "${LOOP}p2"
  install -d mnt
  sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
  if ! tar -xzf "$ARCHIVE" -C mnt
  then
    echo "Extracting $ARCHIVE failed"
    exit 1
  fi
  cp "netboot/boot/$MODLOOP" mnt/boot

  echo "Copy build scripts"
  install -d mnt/mympdos
  find mnt/mympdos/ -name \*~ -delete
  cp -r ../../mympdos/build/* mnt/mympdos

  echo "Copy existing packages"
  install -d mnt/mympdos-apks
  if [ -f "../../repository/$ARCH/APKINDEX.tar.gz" ]
  then
    cp "../../repository/$ARCH/"*.apk mnt/mympdos-apks/
    cp "../../repository/$ARCH/APKINDEX.tar.gz" mnt/mympdos-apks/
  else
    echo "No existing packages found"
  fi
  if [ -f ../../keys/abuild.tgz ]
  then
    echo "Using keys for public repository"
    cp ../../keys/abuild.tgz mnt/mympdos/
  elif [ -f ../../apks/abuild.tgz ]
  then
    echo "Using private build keys"
    cp ../../apks/abuild.tgz mnt/mympdos/
  else
    echo "No saved abuild.tgz found"
  fi
  date +%s > mnt/date
  umount_retry mnt || exit 1
  sudo losetup -d "${LOOP}"

  echo "Patching initramfs"
  cd netboot || exit 1
  rm -f init
  gzip -dc "boot/$INITRAMFS" | cpio -id init
  if ! patch init ../../../mympdos/netboot/init.patch
  then
    echo "Patching netboot init failed"
    exit 1
  fi
  echo ./init | cpio -H newc -o | gzip >> "boot/$INITRAMFS"
  cd ../.. || exit 1
}

build_stage3() {
  echo "myMPDos build stage 3: Starting build"
  $QEMU \
    -M virt -m "$BUILDRAM" -cpu "$CPU" -smp "$BUILDCPUS" \
    -kernel "netboot/boot/$KERNEL" -initrd "netboot/boot/$INITRAMFS" \
    -append "console=ttyAMA0 ip=dhcp" \
    -nographic \
    -drive "file=${BUILDIMAGE},format=raw" \
    -nic user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9
}

build_stage4() {
  echo "myMPDos build stage 4: Saving packages"
  if [ -d ../../apks ]
  then
    BACKUPDATE=$(stat -c"%Y" ../../apks)
    BACKUPDIR=../../apks.$(date -d@"$BACKUPDATE" +%Y%m%d_%H%M)
    mv ../../apks "$BACKUPDIR"
  fi
  install -d "../../apks/$ARCH"
  LOOP=$(sudo losetup --partscan --show -f "$BUILDIMAGE")
  sudo mount -text4 "${LOOP}p2" mnt || exit 1
  if [ -f mnt/build/abuild.tgz ]
  then
    cp mnt/build/abuild.tgz ../../apks/
  else
    echo "No abuild.tgz found"
  fi
  if [ -f "mnt/build/packages/package/${ARCH}/APKINDEX.tar.gz" ]
  then
    cp mnt/build/packages/package/"${ARCH}"/* "../../apks/$ARCH/"
    cp mnt/build/packages/package/"${ARCH}"/* "../../repository/$ARCH/"
  else
    echo "No APKINDEX.tar.gz found"
  fi
  umount_retry mnt || exit 1
  sudo losetup -d "${LOOP}"
}

build_stage5() {
  echo "myMPDos build stage 5: Create image"
  dd if=/dev/zero of="$IMAGE" bs=1M count="$IMAGESIZE"
  sfdisk "$IMAGE" <<< "1, ${BOOTPARTSIZE}, b, *"

  LOOP=$(sudo losetup --partscan --show -f "$IMAGE")
  [ "$LOOP" = "" ] && exit 1
  sudo mkfs.vfat "${LOOP}p1"
  install -d mnt
  sudo mount -ouid="$BUILDUSER" "${LOOP}p1" mnt || exit 1
  if ! tar -xzf "$ARCHIVE" -C mnt
  then
    echo "Extracting $ARCHIVE failed"
    exit 1
  fi
  cd ../../mympdos/overlay || exit 1
  if ! tar -czf ../../$TMPDIR/mnt/mympdos-bootstrap.apkovl.tar.gz .
  then
    echo "Creating overlay failed"
    exit 1
  fi
  cd ../../$TMPDIR || exit 1
  if [ "$PRIVATEIMAGE" = "true" ]
  then
    echo "Copy private bootstrap.txt"
    cp ../../mympdos/bootstrap.txt mnt/
  else
    echo "Copy sample bootstrap.txt files"
    cp ../../mympdos/bootstrap-*.txt mnt/
  fi
  echo "Copy mpd.conf configurations"
  [ -f ../../mympdos/mpd.replace ] && cp ../../mympdos/mpd.replace mnt/
  [ -f ../../mympdos/mpd.conf ] && cp ../../mympdos/mpd.conf mnt/
  echo "Copy usercfg.txt"
  cp ../../mympdos/usercfg.txt mnt/
  echo "Setting version to $VERSION"
  echo "$VERSION" > mnt/myMPDos.version

  echo "Copy myMPDos archive signing public key"
  install -d mnt/mympdos-apk-keys/
  tar --wildcards --strip-components=1 -xzf ../../apks/abuild.tgz -C mnt/mympdos-apk-keys/ ".abuild/*.rsa.pub"

  umount_retry mnt || exit 1
  sudo losetup -d "${LOOP}"
  install -d ../images
  mv "$IMAGE" ../images
  [ "$COMPRESSIMAGE" = "true" ] && gzip "../../images/$IMAGE"

  echo ""
  echo "Image $IMAGE created successfully"
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
  [ -f $TMPDIR/.mympdos-tmp ] || exit 0
  rm -fr $TMPDIR
  echo "Removing old images"
  find ./images -name \*.img -mtime "$KEEPIMAGEDAYS" -delete
  find ./images -name \*.img.gz -mtime "$KEEPIMAGEDAYS" -delete
  echo "Removing old package directories"
  find ./ -maxdepth 1 -type d -name apks.\* -mtime "$KEEPPACKAGEDAYS" -exec rm -rf {} \;
}

umountbuild() {
  echo "Umounting build environment"
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
    install_tmp
    build_stage1
    ;;
  stage2|2)
    check_deps
    install_tmp
    build_stage2
    ;;
  stage3|3)
    check_deps
    install_tmp
    build_stage3
    ;;
  stage4|4)
    check_deps
    install_tmp
    build_stage4
    ;;
  stage5|5)
    check_deps
    install_tmp
    build_stage5
    ;;
  build|b)
    check_deps
    install_tmp
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
