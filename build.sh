#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later
# myMPDos (c) 2020-2026 Juergen Mang <mail@jcgames.de>
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
  for DEP in wget tar gzip dd losetup sfdisk mkfs.vfat mkfs.ext4 sudo install
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

register_binfmt() {
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
}

build_packages() {
  # This will be the build volume
  mkdir -p "$TMPDIR/build"
  mkdir -p "$TMPDIR/apk-cache"
  # Archive signing key
  if [ -f "$STARTPATH/keys/abuild.tgz" ]
  then
    echo "Using keys for public repository"
    cp "$STARTPATH/keys/abuild.tgz" "$TMPDIR/build/"
  elif [ -f "$STARTPATH/apks/abuild.tgz" ]
  then
    echo "Using private build keys"
    cp "$STARTPATH/apks/abuild.tgz" "$TMPDIR/build/"
  else
    echo "No saved abuild.tgz found"
  fi
  docker run --rm \
    -v "$TMPDIR/apk-cache":"/var/cache/apk":Z \
    -v "${STARTPATH}/mympdos/build":"/mympdos":Z \
    -v "$TMPDIR/build":"/build":Z \
    -v "${STARTPATH}/repository/$ARCH":"/build/packages/package/$ARCH":Z \
    --platform linux/arm64/v8 -it arm64v8/alpine \
    /bin/sh
    #/mympdos/build.sh
}

build_image() {
  echo "Create myMPDos image"
  install_tmp
  if [ ! -f "$TMPDIR/$ARCHIVE" ]
  then
    echo "Getting $ARCHIVE"
    wget "${ALPINE_MIRROR}/v${ALPINE_MAJOR_VERSION}/releases/${ARCH}/$ARCHIVE" \
      -O "$TMPDIR/$ARCHIVE"
    if ! tar -tzf "$TMPDIR/$ARCHIVE" > /dev/null
    then
      echo "Can not extract $ARCHIVE"
      rm -f "$ARCHIVE"
      exit 1
    fi
  fi
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
  private)
    PRIVATEIMAGE="true";;
  *)
    PRIVATEIMAGE="false";;
esac

case "$1" in
  register|r)
    register_binfmt
    ;;
  packages|p)
    build_packages
    ;;
  image|i)
    check_deps
    build_stage5
    ;;
  umountbuild|u)
    umountbuild
    ;;
  cleanup|c)
    cleanup
    ;;
  *)
    echo "Usage: $0 (r|p|i|c|u) [private|public]"
    echo ""
    echo "  register|r:     Registers binfmt with QEMU for different architectures"
    echo "  packages|p:     Builds the packages"
    echo "  image|i:        Creates the image"
    echo ""
    echo "  cleanup|c:      cleanup things"
    echo "  umountbuild|u:  removes dangling mounts and loop devices"
    echo ""
    echo "  private:        creates a image with a productive bootstrap.txt file"
    echo "  public:         creates a image with sample bootstrap.txt files (default)"
    exit 2
    ;;
esac
