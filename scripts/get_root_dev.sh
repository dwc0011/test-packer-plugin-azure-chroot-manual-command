#!/bin/bash
# Script to return the NVMe device backing /dev/mapper/rootvg-rootlv on Azure RHEL9

LV_PATH="/dev/mapper/rootvg-rootlv"

# Verify the LV exists
if [ ! -e "$LV_PATH" ]; then
    echo "Error: $LV_PATH not found."
    exit 1
fi

# Get VG name (should be rootvg)
VG_NAME=$(lvs --noheadings -o vg_name "$LV_PATH" | awk '{print $1}')

# Find the physical volume(s) in that VG
PV_DEV=$(pvs --noheadings -o pv_name,vg_name | awk -v vg="$VG_NAME" '$2==vg {print $1}' | head -n1)

# Resolve symlink to the real NVMe device
ROOT_DEV=$(realpath "$PV_DEV")

if [[ -z "$ROOT_DEV" ]]; then
    echo "No NVMe device found for $LV_PATH"
    exit 2
fi

echo "$ROOT_DEV"
