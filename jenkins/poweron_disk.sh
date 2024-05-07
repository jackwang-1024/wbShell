#!/bin/bash
#
# This script triggers a hot reset on a dead pci-device's upstream pci switch port,
# in order to re-enable this device.
# The pci switch port address was reported when calling "poweroff_disk.sh" to disable
# the pci device.
#
# Usage example:
# $ poweron_disk.sh 0000:83:0a.0 /mnt/00230356000D0C39
#
# "0000:83:0a.0":  is the pci switch port address that connects to the disk.
# "/mnt/00230356000D0C39": the disk used to mount at this dir before removal.
#
# After running the above cmd, the disk will be re-enabled and mounted to
# "/mnt/00230356000D0C39".
#remove mount point

if [ $# -lt 1 ]; then
  echo "usage: $0 [address of pci switch port connecting to the device] "
  exit 1
fi

port=$1
echo "upstream pci switch port=$port"

#if [ $# -eq 2 ]; then
#  mount_point=$2
#fi

# 1. hot reset pci switch port
echo "will perform hot reset on port $port"
bc=$(setpci -s $port BRIDGE_CONTROL)
echo "current bridge control=0x$bc"
newbc=$((0x$bc | 0x40))
newbc_hex=$(printf "%04x" $newbc)
echo "will write bridge control new value=0x$newbc_hex"
setpci -s $port BRIDGE_CONTROL=$newbc_hex
sleep 0.01
setpci -s $port BRIDGE_CONTROL=$bc
sleep 0.5

# 2. rescan pci switch port
echo "will rescan pci switch port $port"
echo 1 > "/sys/bus/pci/devices/$port/rescan"
sleep 1

## 3. remount the disk
#if [ -z $mount_point ]; then
#  exit 0
#fi
#
#echo "will remount the disk to \"$mount_point\""
## clean up the mount point
#umount $mount_point
#sleep 1

# in case of a hot-removal and re-enable, the mount point should be cleaned up
# before remount.
#systemctl daemon-reload
sleep 1

# find out the device name
str=`ls -l /sys/block | grep -i $port`
if [ -z str ]; then
  echo "the device at pci port $port isn't found after rescan"
  exit 1
fi

echo "the device at pci port $port is $str"

set -f
arr=(${str//\// })
dev=${arr[-1]}
echo "the device name=$dev"
dev="/dev/$dev"
#if mount $dev $mount_point; then
#  echo "have mounted $dev to $mount_point"
#  exit 0
#else
#  echo "failed to mount device $dev to $mount_point"
#  exit 1
#fi
