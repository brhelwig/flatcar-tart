#!/usr/bin/env bash
set -euo pipefail

variant=$1
flatcar_version=$2
k3s_version=$3
output=$4

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
butane_image=quay.io/coreos/butane:release
disk_bytes=20000000000

butane() {
  docker run --rm -i -v "$work:/files:ro" "$butane_image" --strict --files-dir /files
}

butane < "$repo/butane/base.yaml" > "$work/base.ign"

case "$variant" in
  flatcar)
    cp "$work/base.ign" "$work/config.ign"
    ;;
  flatcar-k3s)
    k3s_minor=$(echo "$k3s_version" | cut -d. -f1-2)
    sed -e "s/@K3S_VERSION@/$k3s_version/g" -e "s/@K3S_MINOR@/$k3s_minor/g" \
      "$repo/butane/k3s.yaml" | butane > "$work/config.ign"
    ;;
  *)
    echo "unknown variant: $variant" >&2
    exit 1
    ;;
esac

curl -fsSL -o "$work/flatcar-install" \
  https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install
chmod +x "$work/flatcar-install"

rm -f "$work/disk.img"
truncate -s "$disk_bytes" "$work/disk.img"
loop=$(sudo losetup -fP --show "$work/disk.img")
trap 'sudo umount "$work/oem" 2>/dev/null || true; sudo losetup -d "$loop" 2>/dev/null || true' EXIT

sudo "$work/flatcar-install" -d "$loop" -B arm64-usr -C stable -V "$flatcar_version" -i "$work/config.ign"

sudo partprobe "$loop" || true
sudo udevadm settle
oem_dev=$(sudo blkid -l -t LABEL=OEM -o device "$loop"p*)
mkdir -p "$work/oem"
sudo mount "$oem_dev" "$work/oem"
echo 'set linux_console="console=hvc0 console=tty0"' | sudo tee -a "$work/oem/grub.cfg" > /dev/null
sudo umount "$work/oem"
sudo losetup -d "$loop"
trap - EXIT

zstd -T0 -f "$work/disk.img" -o "$output"
rm -rf "$work"
