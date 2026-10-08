#!/usr/bin/env bash
set -euo pipefail

variant=$1
flatcar_version=$2
disk=$3
repository=$4
source_url=$5

vm_dir="${TART_HOME:-$HOME/.tart}/vms/$variant"

tart delete "$variant" 2>/dev/null || true
tart create --linux --disk-size 20 "$variant"
zstd -d -f "$disk" -o "$vm_dir/disk.img"
tart set "$variant" --cpu 2 --memory 2048

tart push "$variant" \
  --label "org.opencontainers.image.source=$source_url" \
  "$repository/$variant:$flatcar_version" \
  "$repository/$variant:stable" \
  "$repository/$variant:latest"
