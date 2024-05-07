#!/bin/bash
#
# This script disable a nvme disk to simulate a disk removal at runtime.
#
# Usage example:
# $ ./poweroff_disk.sh nvme2n1
#
# The cmd above will disable disk /dev/nvme2n1. All IO to this disk will fail immediately.
# If the disk was mounted before, the mount point remains there.
# The cmd will output the disk's "upstream pci switch address" and "mount point" if any.
# Caller must remember the "upstream pci switch address" because it is needed by subsequent
# calls to "poweron_disk.sh" to re-enable the disk.
# The "mount point" is needed only if user wants the disk be re-mounted to the same location
# when it's re-enabled.

if [ $# -lt 1 ]; then
  echo usage: $0 [device name such as nvme0n1]
  exit 1
fi

# sanity check.
if [ ! -d "/sys/block/$1" ]; then
  echo "device $1 not exist in /sys/block/"
  exit 1
fi

# check if this disk is mounted.
str=`df -h | grep -i $1`
if [ -z "$str" ]; then
  echo device $1 is not mounted to filesystem
else
  mount_point=`echo $str | awk -F " " '{print $6}'`
  echo device \"$1\" is mounted at \"$mount_point\"
fi

str=`ls -l /sys/block/$1`
# str format is "lrwxrwxrwx 1 root root 0 Apr  2 12:32 /sys/block/nvme0n1 -> ../devices/pci0000:80/0000:80:03.0/0000:82:00.0/0000:83:01.0/0000:84:00.0/nvme/nvme0/nvme0n1"

# 1. find pci full address for the given device.
set -f
arr=(${str//\// })
len=${#arr[@]}
if [ $len -lt 5 ]; then
  echo "incorrect string format: $str"
  exit 1
fi

#echo "device path split:"
#for i in "${!arr[@]}"; do
#  echo "$i => ${arr[i]}"
#done

((idx=len-4))
dev=${arr[$idx]}
if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
  echo "Error: device $dev not found"
  exit 1
fi

port=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$dev")))
if [ ! -e "/sys/bus/pci/devices/$port" ]; then
  echo "Error: device $port not found"
  exit 1
fi

# NOTE: please remember the pci switch address, because you will need this
# address when running "poweron_pci.sh" to re-enable this device.
echo "before poweroff, device=$str"
echo "device pci address=$dev, upstream pci switch port=$port, mount_point=$mount_point"

# 2. remove device
echo "will remove $dev"
echo 1 > "/sys/bus/pci/devices/$dev/remove"
sleep 1
echo "have removed $dev"
