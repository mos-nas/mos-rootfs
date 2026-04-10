#!/bin/bash
echo "nameserver 10.0.0.5" > /etc/resolv.conf

ARCHITECTURE="$(uname -m)"
if [ "$ARCHITECTURE" == "x86_64" ] ; then
  NODE_PKG_ARCH="x64"
  ADDITIONAL_PACKAGES=""
elif [ "$ARCHITECTURE" == "aarch64" ] ; then
  NODE_PKG_ARCH="arm64"
  ADDITIONAL_PACKAGES="device-tree-compiler"
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends --no-install-suggests curl wget nano htop util-linux e2fsprogs dmidecode \
  iputils-ping jq openssh-server parted nvme-cli xfsprogs btrfs-progs ifupdown resolvconf udev git bridge-utils acpid git smbclient linux-cpupower \
  isc-dhcp-client acpi-support-base nginx tree samba xz-utils rsyslog ntpsec kbd console-data hdparm smartmontools at netcat-openbsd cryptsetup \
  net-tools sysstat pciutils usbutils nut-server beep inotify-tools libjson-glib-1.0-0 libxml2 libpciaccess0 open-iscsi tgt dos2unix dosfstools \
  iptables libpixman-1-0 libspice-server1 libusbredirparser1 dnsmasq lm-sensors gnutls-bin cron rsync fuse3 nfs-kernel-server nfs-common libpng16-16 \
  wireguard-tools bash-completion libxml2-utils yq ethtool attr xattr psmisc mc bcache-tools gettext-base "$ADDITIONAL_PACKAGES"

DEB_APPS=$(ls -1 /tmp/applications/*.deb)
for deb_app in $DEB_APPS; do
  /usr/bin/apt -y install $deb_app
done

rm -rf /bin/sh
ln -sf /bin/bash /bin/sh

mv /usr/bin/apt /usr/bin/apt.orig
mv /usr/bin/apt-get /usr/bin/apt-get.orig

chmod +x /init
chmod 755 /etc/init.d/*
chmod 755 /usr/local/bin/*
chmod 644 /etc/ssh/sshd_config
chmod 755 /usr/bin/apt

cd /usr/bin

ln -sf /usr/bin/apt /usr/bin/apt-get

cd /etc/rc2.d
if [ -f /etc/rc2.d/S01start-mos ] ; then
  mv /etc/rc2.d/S01start-mos /etc/rc2.d/S98start-mos
else
  ln -sf ../init.d/start-mos S98start-mos
fi
# add cpupower
ln -sf ../init.d/cpupower S03cpupower

cd /etc/rc0.d
if [ ! -f /etc/rc0.d/K01stop-mos ] ; then
  ln -sf ../init.d/stop-mos K01stop-mos
fi

cd /etc/rc6.d
if [ ! -f /etc/rc6.d/K01stop-mos ] ; then
  ln -sf ../init.d/stop-mos K01stop-mos
fi

# Remove default startup symlinks
rm -f /etc/rcS.d/S15lm-sensors /etc/rcS.d/K13iscsid /etc/rcS.d/K13open-iscsi /etc/rcS.d/S11brightness /etc/rcS.d/S14nfs-common \
  /etc/rcS.d/S16mountnfs-bootclean.sh /etc/rcS.d/S15mountnfs.sh /etc/rcS.d/S07cryptdisks-early /etc/rcS.d/S08cryptdisks /etc/rcS.d/S03udev

rm -f /etc/rc0.d/K01nginx /etc/rc0.d/K01nmbd /etc/rc0.d/K01nut-client /etc/rc0.d/K01nut-server /etc/rc0.d/K01open-iscsi \
  /etc/rc0.d/K01samba-ad-dc /etc/rc0.d/K01smbd /etc/rc0.d/K01tgt /etc/rc0.d/K02iscsid /etc/rc0.d/K09cryptdisks \
  /etc/rc0.d/K10cryptdisks-early /etc/rc0.d/K02dnsmasq

rm -f /etc/rc2.d/S02docker /etc/rc2.d/S02lxc /etc/rc2.d/S02lxc-net /etc/rc2.d/S02nginx /etc/rc2.d/S02smbd /etc/rc2.d/S01samba-ad-dc \
  /etc/rc2.d/S02virtlogd /etc/rc2.d/S02ssh /etc/rc2.d/S04libvirt-guests /etc/rc2.d/S01nmbd /etc/rc2.d/S02ntpsec /etc/rc2.d/S02nut-server \
  /etc/rc2.d/S03nut-client /etc/rc2.d/S02tgt /etc/rc2.d/S03nginx /etc/rc2.d/S03nfs-kernel-server /etc/rc2.d/S03cron /etc/rc2.d/S02smartmontools \
  /etc/rc2.d/S03libvirtd /etc/rc2.d/S02dnsmasq

rm -f /etc/rc5.d/S03cron /etc/rc5.d/S02dnsmasq

rm -f /etc/rc6.d/K01nginx /etc/rc6.d/K01nmbd /etc/rc6.d/K01nut-client /etc/rc6.d/K01nut-server /etc/rc6.d/K01open-iscsi \
  /etc/rc6.d/K01samba-ad-dc /etc/rc6.d/K01smbd /etc/rc6.d/K01tgt /etc/rc6.d/K02iscsid /etc/rc6.d/K09cryptdisks \
  /etc/rc6.d/K10cryptdisks-early /etc/rc6.d/K02dnsmasq

# Move rc scripts
mv /etc/rcS.d/S11resolvconf /etc/rcS.d/S12resolvconf
mv /etc/rcS.d/S12networking /etc/rcS.d/S11networking
mv /etc/rc2.d/S04stop-bootlogd /etc/rc2.d/S99stop-bootlogd

# Disable Smartmontools Mail service
mv /etc/smartmontools/run.d/10mail /etc/smartmontools/run.d/10mail.disabled

# Inject default hostname
echo "MOS" > /etc/hostname

# Inject text into fstab
echo "# By default empty fstab for MOS" > /etc/fstab

# Create target directory
mkdir -p /etc/target

# Remove default logs/config/udev files
rm -rf /var/log/* /etc/ssh/*_key* /var/lib/lxc /var/lib/docker rm -rf /var/www/* /etc/init.d/.depend* /etc/nut/* /lib/udev/rules.d/85-hdparm.rules

# Sert permissionsions
chown -R www-data:www-data /var/www

groupadd -g 500 mos
useradd -u 500 -g 500 -M -s /usr/sbin/nologin mos
groupadd -g 64055 -r libvirt-qemu
useradd -r -g libvirt-qemu -s /sbin/nologin -d /var/lib/libvirt/qemu libvirt-qemu
groupadd -g 112 -r libvirt
groupadd -g 103 -r kvm
usermod -a -G kvm,libvirt-qemu libvirt-qemu
groupadd -g 115 -r docker
usermod -a -G nut nut

groupdel sambashare

cd /etc
ln -sf /proc/mounts mtab

cd /tmp
if ! wget -O /tmp/node.xz https://nodejs.org/dist/v${1}/node-v${1}-linux-${NODE_PKG_ARCH}.tar.xz ; then
  exit 1
fi
tar -xf /tmp/node.xz
mkdir -p /usr/share/doc/node
mv /tmp/node-*/LICENSE* /tmp/node-*/share/doc/node/
rm -f /tmp/node-*/CHANGE* /tmp/node-*/README*
cp -R /tmp/node-*/* /usr/

# /etc/passwd editieren:
sed -i '/^root::/c root::0:0:root:/root:/bin/bash' /etc/passwd

# make cron less verbose
echo -e "\n# MOS Custom - make cron less verbose\nEXTRA_OPTS='-L 5'" >> /etc/default/cron

# Clean up /usr/share/doc directory
find /usr/share/doc -type f ! -name "copyright*" ! -name "COPYRIGHT*" ! -name "license*" ! -name "LICENSE*" ! -name "LICENCE*" \
  ! -name "licence*" ! -name "NOTICE*" ! -name "notice*" ! -name "COPYING*" ! -name "copying*" -delete
find /usr/share/doc -type d -empty -delete

rm -rf /home

rm -rf /usr/include/* /usr/local/games /usr/local/include/* /usr/share/*/include/
find /usr/* -name "*.a" -exec rm -f {} \; 2>/dev/null
rm -rf /usr/share/man /usr/share/doc-base /usr/share/info /usr/share/help
rm -rf /usr/share/qemu/edk2-* /usr/bin/qemu-aarch64* /usr/bin/qemu-system-aarch64
rm -rf /etc/network/interfaces /etc/network/interfaces.d
touch /etc/network/interfaces
find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name "en*" ! -name "C" ! -name "POSIX" -exec rm -rf {} \;
rm -rf /var/cache/apt/* /var/cache/apt/.*

chown -R root:root /tmp/rootfs_files
chmod -R 755 /tmp/rootfs_files
cp -R /tmp/rootfs_files/* /

# Create MOS temp directory & plugins directory
mkdir -p /var/mos
mkdir -p /usr/bin/mos

# Make sure to make mos-install not executable
chmod -x /usr/local/bin/mos-install

exit
