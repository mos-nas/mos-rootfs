#!/bin/bash
# This is just an example how you could build the MOS rootfs manually
# Please make sure to run this in a containerized environment(preferrably
# in a Devuan Daedalus LXC container)

# Set environment Variables
WORKDIR=/root/mos-rootfs
NODE_VERSION=24.13.0
CHANNEL=beta
VERSION=0.1.13
KERNEL_V=6.18.5


# Install dependencies
apt-get update && apt-get -y install debootstrap xz-utils cpio jq wget

# Clone Repository
cd $WORKDIR
git clone https://github.com/ich777/mos-rootfs

# Setup rootfs
debootstrap --variant=minbase excalibur $WORKDIR/rootfs https://pkgmaster.devuan.org/merged
cp -R $WORKDIR/mos-rootfs/rootfs_files $WORKDIR/rootfs/tmp/
cp $WORKDIR/mos-rootfs/chroot-script.sh $WORKDIR/rootfs/tmp/chroot-script.sh
chmod +x ${WORKDIR}/rootfs/tmp/chroot-script.sh

# Create applications directory in rootfs
mkdir -p $WORKDIR/rootfs/tmp/applications

# Define application_download and md5 check function
application_download() {
  if [ "$1" == "docker" ] ; then
    REPO="moby"
  else
    REPO="$1"
  fi

  echo "Downloading: mos-$1_$2_amd64.deb$4"
  curl --progress-bar -L \
    --header "Accept: application/octet-stream" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --output "$WORKDIR/rootfs/tmp/applications/mos-$1_$2_amd64.deb$4" \
    "https://api.github.com/repos/ich777/mos-$REPO/releases/assets/$3"
  if [ "$4" == ".md5" ] ; then
    if [ "$(md5sum $WORKDIR/rootfs/tmp/applications/mos-$1_$2_amd64.deb | awk '{print $1}')" != "$(cat $WORKDIR/rootfs/tmp/applications/mos-$1_$2_amd64.deb$4)" ] ; then
      echo "Checksum error from file: mos-$1_$2_amd64.deb"
      exit 1
    fi
  fi
}
      
# Get Docker Releases
DOCKER_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-moby/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define DOCKER_VERSION
DOCKER_VERSION=$(echo $DOCKER_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
DOCKER_DEB=$(echo $DOCKER_JSON | jq --arg version v${DOCKER_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-docker") and endswith(".deb")) | .id')
DOCKER_DEB_MD5=$(echo $DOCKER_JSON | jq --arg version v${DOCKER_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-docker") and endswith(".deb.md5")) | .id')

# Get LXC Releases
LXC_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-lxc/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define LXC_VERSION
LXC_VERSION=$(echo $LXC_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
LXC_DEB=$(echo $LXC_JSON | jq --arg version v${LXC_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-lxc") and endswith(".deb")) | .id')
LXC_DEB_MD5=$(echo $LXC_JSON | jq --arg version v${LXC_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-lxc") and endswith(".deb.md5")) | .id')

# Get QEMU Releases
QEMU_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-qemu/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define QEMU_VERSION
QEMU_VERSION=$(echo $QEMU_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
QEMU_DEB=$(echo $QEMU_JSON | jq --arg version v${QEMU_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-qemu") and endswith(".deb")) | .id')
QEMU_DEB_MD5=$(echo $QEMU_JSON | jq --arg version v${QEMU_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-qemu") and endswith(".deb.md5")) | .id')

# Get SnapRAID Releases
SNAPRAID_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-snapraid/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define SNAPRAID_VERSION
SNAPRAID_VERSION=$(echo $SNAPRAID_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
SNAPRAID_DEB=$(echo $SNAPRAID_JSON | jq --arg version v${SNAPRAID_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-snapraid") and endswith(".deb")) | .id')
SNAPRAID_DEB_MD5=$(echo $SNAPRAID_JSON | jq --arg version v${SNAPRAID_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-snapraid") and endswith(".deb.md5")) | .id')

# Get MergerFS Releases
MERGERFS_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-mergerfs/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define MERGERFS_VERSION
MERGERFS_VERSION=$(echo $MERGERFS_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
MERGERFS_DEB=$(echo $MERGERFS_JSON | jq --arg version v${MERGERFS_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-mergerfs") and endswith(".deb")) | .id')
MERGERFS_DEB_MD5=$(echo $MERGERFS_JSON | jq --arg version v${MERGERFS_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-mergerfs") and endswith(".deb.md5")) | .id')

# Get image-sha Releases
IMAGESHA_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-image-sha/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define IMAGESHA_VERSION
IMAGESHA_VERSION=$(echo $IMAGESHA_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
IMAGESHA_DEB=$(echo $IMAGESHA_JSON | jq --arg version v${IMAGESHA_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-image-sha") and endswith(".deb")) | .id')
IMAGESHA_DEB_MD5=$(echo $IMAGESHA_JSON | jq --arg version v${IMAGESHA_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-image-sha") and endswith(".deb.md5")) | .id')

# Get image-sha Releases
NOTIFY_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-notify/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define NOTIFY_VERSION
NOTIFY_VERSION=$(echo $NOTIFY_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
NOTIFY_DEB=$(echo $NOTIFY_JSON | jq --arg version v${NOTIFY_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-notify") and endswith(".deb")) | .id')
NOTIFY_DEB_MD5=$(echo $NOTIFY_JSON | jq --arg version v${NOTIFY_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-notify") and endswith(".deb.md5")) | .id')

# Get docker-watchdog Releases
DOCKERWD_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-docker-watchdog/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define DOCKERWD_VERSION
DOCKERWD_VERSION=$(echo $DOCKERWD_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
DOCKERWD_DEB=$(echo $DOCKERWD_JSON | jq --arg version v${DOCKERWD_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-docker-watchdog") and endswith(".deb")) | .id')
DOCKERWD_DEB_MD5=$(echo $DOCKERWD_JSON | jq --arg version v${DOCKERWD_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-docker-watchdog") and endswith(".deb.md5")) | .id')

# Get docker-watchdog Releases
WSDDN_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-wsddn/releases?per_page=50" \
  --header "X-GitHub-Api-Version: 2022-11-28")

# Define DOCKERWD_VERSION
WSDDN_VERSION=$(echo $WSDDN_JSON | jq -r '.[].tag_name' | sort -V | tail -1)

# Get Asset IDs
WSDDN_DEB=$(echo $WSDDN_JSON | jq --arg version v${WSDDN_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-wsdd-native") and endswith(".deb")) | .id')
WSDDN_DEB_MD5=$(echo $WSDDN_JSON | jq --arg version v${WSDDN_VERSION#v} -r '.[] | select(.tag_name == $version) | .assets[] | select(.name | startswith("mos-wsdd-native") and endswith(".deb.md5")) | .id')

# Download applications
application_download "docker" "${DOCKER_VERSION#v}" "$DOCKER_DEB"
application_download "docker" "${DOCKER_VERSION#v}" "$DOCKER_DEB_MD5" ".md5"
application_download "lxc" "${LXC_VERSION#v}" "$LXC_DEB"
application_download "lxc" "${LXC_VERSION#v}" "$LXC_DEB_MD5" ".md5"
application_download "qemu" "${QEMU_VERSION#v}" "$QEMU_DEB"
application_download "qemu" "${QEMU_VERSION#v}" "$QEMU_DEB_MD5" ".md5"
application_download "snapraid" "${SNAPRAID_VERSION#v}" "$SNAPRAID_DEB"
application_download "snapraid" "${SNAPRAID_VERSION#v}" "$SNAPRAID_DEB_MD5" ".md5"
application_download "mergerfs" "${MERGERFS_VERSION#v}" "$MERGERFS_DEB"
application_download "mergerfs" "${MERGERFS_VERSION#v}" "$MERGERFS_DEB_MD5" ".md5"
application_download "image-sha" "${IMAGESHA_VERSION#v}" "$IMAGESHA_DEB"
application_download "image-sha" "${IMAGESHA_VERSION#v}" "$IMAGESHA_DEB_MD5" ".md5"
application_download "notify" "${NOTIFY_VERSION#v}" "$NOTIFY_DEB"
application_download "notify" "${NOTIFY_VERSION#v}" "$NOTIFY_DEB_MD5" ".md5"
application_download "docker-watchdog" "${DOCKERWD_VERSION#v}" "$DOCKERWD_DEB"
application_download "docker-watchdog" "${DOCKERWD_VERSION#v}" "$DOCKERWD_DEB_MD5" ".md5"
application_download "wsddn" "${WSDDN_VERSION#v}" "$WSDDN_DEB"
application_download "wsddn" "${WSDDN_VERSION#v}" "$WSDDN_DEB_MD5" ".md5"

############################################################################################
# Modify rootfs
chroot $WORKDIR/rootfs /tmp/chroot-script.sh "$NODE_VERSION"
############################################################################################

# Create MOS release
ROOTFS=$WORKDIR/rootfs
mkdir -p $WORKDIR/release

# Add Memtest86+ License
mkdir -p $ROOTFS/usr/share/doc/memtest86plus
wget -q -O $ROOTFS/usr/share/doc/memtest86plus/LICENSE https://raw.githubusercontent.com/memtest86plus/memtest86plus/refs/heads/main/LICENSE

cd $ROOTFS
rm -rf $ROOTFS/root/.* $ROOTFS/var/log/* $ROOTFS/root/* $ROOTFS/tmp/* $ROOTFS/tmp/.* $ROOTFS/var/lib/apt/lists/* $ROOTFS/etc/init.d/.* $ROOTFS/etc/resolv.conf $ROOTFS/var/cache/apt/* $ROOTFS/var/cache/apt/.*

# Grab latest frontend
FRONTEND_JSON=$(curl -s --request GET \
  --url "https://api.github.com/repos/ich777/mos-frontend/releases/latest" \
  --header "X-GitHub-Api-Version: 2022-11-28")
FRONTEND_V=$(echo $FRONTEND_JSON | jq -r '.tag_name')
FRONTEND_ASSET_ID=$(echo $FRONTEND_JSON | jq -r '.assets[] | select(.name | startswith("mos-frontend") and endswith(".tar.gz")) | .id')

# Download and extract Frontend
curl --progress-bar -L \
  --header "Accept: application/octet-stream" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --output "$WORKDIR/frontend.tar.gz" \
  "https://api.github.com/repos/ich777/mos-frontend/releases/assets/$FRONTEND_ASSET_ID"
tar -C $ROOTFS/var/www/ -xf $WORKDIR/frontend.tar.gz
chown -R root:root $ROOTFS/var/www/
chmod -R 755 $ROOTFS/var/www/

# Get latest API
git clone https://github.com/ich777/mos-api.git --depth=1 $ROOTFS/usr/local/lib/mos-api
API_V=$(date -d @"$(git -C $ROOTFS/usr/local/lib/mos-api log -1 --format=%ct)" "+%Y%m%d-%H%M")
rm -rf $ROOTFS/usr/local/lib/mos-api/.git
chown -R root:root $ROOTFS/usr/local/lib/mos-api
chmod -R 755 $ROOTFS/usr/local/lib/mos-api

RECOMMENDED_KERNEL=${KERNEL_V}-mos

chmod +x $WORKDIR/mos-rootfs/mos-json
$WORKDIR/mos-rootfs/mos-json "$CHANNEL" "$VERSION" "$RECOMMENDED_KERNEL" "$ROOTFS" "$FRONTEND_V" "$API_V" "$NODE_VERSION" > $ROOTFS/etc/mos-release.json
chown root:root $ROOTFS/etc/mos-release.json
chmod 755 $ROOTFS/etc/mos-release.json
cp $ROOTFS/etc/mos-release.json $WORKDIR/release/mos-release.json

echo "Compressing rootfs..."
find . | cpio -o -H newc | xz -C crc32 -9 -T0 > "$WORKDIR/release/rootfs"
md5sum $WORKDIR/release/rootfs | awk '{print $1}' > $WORKDIR/release/rootfs.md5

# This will leave you with the required rootfs file for MOS:
# - rootfs
# and the .md5 checksums
