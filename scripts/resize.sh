#!/bin/bash
# Resize LVM volumes on Azure RHEL9 (sku: 9-lvm-gen2)
# Expands /home by +14G, /root by +12G, and allocates remaining space to /tmp
# Idempotent: skips if already expanded

set -euo pipefail

### CONFIG ###
HOME_INC=14G
ROOT_INC=12G
VG_NAME="rootvg"   # default for Azure RHEL9
LV_HOME="/dev/${VG_NAME}/homelv"
LV_ROOT="/dev/${VG_NAME}/rootlv"
LV_TMP="/dev/${VG_NAME}/tmplv"

### FUNCTIONS ###
err() { echo "ERROR: $*" >&2; exit 1; }

check_lv_exists() {
    local lv=$1
    if ! lvs "$lv" &>/dev/null; then
        err "Logical volume $lv not found!"
    fi
}

get_lv_size_gb() {
    local lv=$1
    lv_size=$(lvs --noheadings --units g -o lv_size "$lv" | awk '{print $1}' | sed 's/[A-Za-z]//g')
    lv_size=${lv_size%.*}
    echo "$lv_size"
}

resize_if_needed() {
    local lv=$1
    local inc=$2
    local target_increase=${inc%G}   # strip "G"
    local current_size
    current_size=$(get_lv_size_gb "$lv")    
    local target_size=$((current_size + target_increase))

    echo "[$lv] Current size: ${current_size}G | Target size after resize: ${target_size}G"

    # Check free space
    FREE_INT=$(vgs --noheadings --units g -o vg_free "$VG_NAME" | awk '{print $1}' | sed 's/[A-Za-z]//g' | cut -d'.' -f1)
    if (( FREE_INT < target_increase )); then
        err "Not enough free space to grow $lv by $inc. Available: ${FREE_INT}G"
    fi

    # Resize
    echo "Resizing $lv by +$inc..."
    lvresize -r -L +"$inc" "$lv"
}

### MAIN ###

echo "Running pvscan to ensure updated PV info..."
pvscan >/dev/null
echo "Running pvresize to refresh physical volumes..."
for pv in $(pvs --noheadings -o pv_name); do
    pvresize "$pv" || true
done


lvscan >/dev/null
# Resize /home if not already done
check_lv_exists "$LV_HOME"
resize_if_needed "$LV_HOME" "$HOME_INC"

lvscan >/dev/null
# Resize /root if not already done
check_lv_exists "$LV_ROOT"
resize_if_needed "$LV_ROOT" "$ROOT_INC"

lvscan >/dev/null
# Allocate remaining free space to /tmp
check_lv_exists "$LV_TMP"
FREE_INT=$(vgs --noheadings --units g -o vg_free "$VG_NAME" | awk '{print $1}' | sed 's/[A-Za-z]//g' | cut -d'.' -f1)
if (( FREE_INT > 0 )); then
    echo "Resizing /tmp with remaining ${FREE_INT}G..."
    lvresize -r -l +100%FREE "$LV_TMP"
else
    echo "No free space left for /tmp."
fi

echo "Resize complete."
lsblk
