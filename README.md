# Introduction

This repository is a collection of resources for installing linux on PowerPC based routerboards (RB333,RB600,RB800).
Unfortunatly I only own an RB600 as such that is my only test bed.


# Partitioning

RouterBOOT when setup to boot it will try to load a kernel by executing the partition with type 0x27 as a kernel image.
There does not seem to be a way to use initrd, as such some modules must be build in to the kernel image.
Also kernel must not be above a certain size or it will not boot (4MB uncompressed??) which makes it a bit difficult especially when you try to debug modules.

# Boot parameters

RouterBOOT passes only the bare minimum parameters to the kernel and there is no way to customise it. However the kernel image is wrapped with a loader that allows it to be changed through Serial console.
It is also possible to give the kernel extra parameters that are merged with the ones passed from the bootloader using powerpc-linux-gnu-objcopy to add a section named "kernparm" to the binary.

# Installing various linux distributions

## OpenWRT 

(Soon)

## Debian 8/9 Initial Setup

This is a two stage process using either debootstrap or cdebootstrap

1. On an other machine that can read/write CompactFlash cards

  a. Create a VERY basic debian installation that has the bare minimum and the packages in the /debootstrap folder.

  b. Configure fstab, hostname and network interfaces

2. On the routerboard

  a. On the first boot redirect init to /bin/sh and run the actuall package installation

  b. Reboot and install the rest of the needed packages

sudo debootstrap --foreign --arch powerpc stretch chroot/ http://httpredir.debian.org/debian/
sudo echo "/dev/sda2 / ext4 defaults 0 0" > chroot/etc/fstab
sudo echo "<device-fqdn>" > /etc/hostname
sudo cat >> /etc/network/interfaces  <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
sudo cp -a <modules_dir> chroot/lib/ 


And on the device boot with `init=/bin/sh` as a kernel parameter for the first time and do the following:

mount -o remount,rw /
LC_ALL=C LANGUAGE=C LANG=C /debootstrap/debootstrap --second-stage


Set networking up 
ifup eth0
apt-get update
apt-get install locales openssh-server bash-completion
