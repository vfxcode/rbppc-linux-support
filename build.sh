#!/bin/bash
WORKDIR="$(dirname $(readlink -f $0))"
TREEDIR="${WORKDIR}/../linux"
OUTDIR="${WORKDIR}/bin"
PATCHDIR="${WORKDIR}/patches"
KERNELFILE="${TREEDIR}/arch/powerpc/boot/dtbImage.rb600.elf"
CONFIGBACKUP="${WORKDIR}/configs/rb600.$(date +%Y%m%d.%H%M%S).config"
KERNELPARAMETERS="root=/dev/sda2"
TARGETUSER="vfxcode"
TARGETHOST="10.29.88.3"
TARGETDIR="~/rb600"
CONCJ=5

export ARCH=powerpc

cd "${TREEDIR}"

egrep "^(VERSION|PATCHLEVEL|SUBLEVEL|EXTRAVERSION)" Makefile | tr -d ' ' > ${WORKDIR}/version.tmp
. ${WORKDIR}/version.tmp
VERSION="${VERSION}-${PATCHLEVEL}-${SUBLEVEL}-rb600"
rm ${WORKDIR}/version.tmp

function build () {
  echo "Backing up .config"
  cp .config ${CONFIGBACKUP}
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Could not backup config"
    exit
  else
    echo "  Current config here ${CONFIGBACKUP}"
  fi

  echo "Building kernel"

  make -j $CONCJ
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Kernel build error ($RT)"
    exit
  fi

  if [ ! -f "$KERNELFILE" ]; then
    echo "Kernel File not found"
    exit
  fi
  cp "${KERNELFILE}" "${OUTDIR}/vmlinux-${VERSION}"

  echo "Adding kernel parameters"
  echo "  (${KERNELPARAMETERS})"
  echo "${KERNELPARAMETERS}" > "${OUTDIR}/kernparam.dat"
  powerpc-linux-gnu-objcopy --add-section kernparm="${OUTDIR}/kernparam.dat" "${OUTDIR}/vmlinux-${VERSION}"
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Kernel modules install error ($RT)"
    exit
  fi


  echo "Package modules"
  make -j $CONCJ INSTALL_MOD_PATH=${OUTDIR}/ modules_install
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Kernel modules install error ($RT)"
    exit
  fi
}


function install() {
  echo "Copying Kernel to target board"
  scp -q "${OUTDIR}/vmlinux-${VERSION}" ${TARGETUSER}@${TARGETHOST}:${TARGETDIR}
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Could not copy kernel to host"
    exit
  fi

  echo "Copying modules to target board"
  rsync -a "${OUTDIR}/lib/" ${TARGETUSER}@${TARGETHOST}:${TARGETDIR}/lib/
  RT=$?
  if [ $RT -ne 0 ] ; then
    echo "Could not copy modules to host"
    exit
  fi

  echo "dd if=/tmp/vmlinux of=/dev/sda1 bs=512k"
}

case $1 in
  build) build ;;
  install) install;;
  *) exit ;;
esac

