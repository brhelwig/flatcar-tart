#!/usr/bin/env bash
set -euo pipefail

variant=$1
flatcar_version=$2
disk=$3
repository=$4
source_url=$5

repo=$(cd "$(dirname "$0")/.." && pwd)
vm_dir="${TART_HOME:-$HOME/.tart}/vms/$variant"

rm -rf "$vm_dir"
mkdir -p "$vm_dir"
cp "$repo/tart/config.json" "$repo/tart/nvram.bin" "$vm_dir/"
zstd -d -f "$disk" -o "$vm_dir/disk.img"

tart push "$variant" \
  --label "org.opencontainers.image.source=$source_url" \
  "$repository/$variant:$flatcar_version" \
  "$repository/$variant:stable" \
  "$repository/$variant:latest"
