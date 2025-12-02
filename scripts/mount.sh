#!/bin/bash
set -euxo pipefail

export DNF_VAR_ocidomain="oracle.com"
export DNF_VAR_ociregion=""

export SPEL_AMIGENBRANCH="main"
export SPEL_AMIGENPKGGRP="core"
export SPEL_AMIGENREPOS="${SPEL_AMIGENREPOS:-spel,packages-microsoft-com-prod,rhel-9-for-x86_64-appstream-rhui-rpms,rhel-9-for-x86_64-baseos-rhui-rpms,rhel-9-for-x86_64-supplementary-rhui-rpms,rhui-microsoft-azure-rhel9}"
export SPEL_USEDEFAULTREPOS="false"
export SPEL_AMIGENREPOSRC="https://spel-packages.cloudarmor.io/spel-packages/repo/spel-release-latest-9.noarch.rpm"
export SPEL_AMIGEN9SOURCE="https://github.com/dwc0011/amigen9.git"
export SPEL_AMIGENBRANCH="chroot"
export SPEL_AMIGENSTORLAY="/:rootVol:6,swap:swapVol:2,/home:homeVol:1,/var:varVol:2,/var/tmp:varTmpVol:2,/var/log:logVol:2,/var/log/audit:auditVol:100%FREE"
export SPEL_AMIGENVGNAME="VolGroup00"
export SPEL_AMIUTILSSOURCE=""
export SPEL_BOOTLABEL="/boot"
export SPEL_BUILDDEPS="dosfstools git lvm2 parted python3-pip unzip yum-utils"
export SPEL_BUILDNAME="${SOURCE_NAME_ENV}"
export SPEL_CLOUDPROVIDER="azure"
export SPEL_EXTRARPMS="crypto-policies-scripts,spel-release,spel-dod-certs,spel-wcf-certs,WALinuxAgent"
export SPEL_FIPSDISABLE="false"
export SPEL_GRUBTMOUT="1"
export SPEL_HTTP_PROXY=""


export SPEL_AMIGENBOOTDEVLBL="boot_disk"
export SPEL_AMIGENBOOTDEVSZ="768"
export SPEL_AMIGENBOOTDEVSZMLT="1.1"
export SPEL_AMIGENMANFST=""
export SPEL_AMIGENROOTNM=""
export SPEL_AMIGENUEFIDEVLBL="UEFI_DISK"
export SPEL_AMIGENUEFIDEVSZ="128"
export SPEL_USEROOTDEVICE="false"

dnf update -y --disablerepo='*' --enablerepo='*microsoft*'
yum -y update
/packerbuild/spel/spel/scripts/builder-prep-9.sh

/packerbuild/spel/spel/scripts/amigen9-build.sh
