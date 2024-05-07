#!/bin/bash

. ./iscsiTest.sh

echo "共4个参数,用空格分开 sp volume-number volume-size volue-unit"

if [ $# -eq 0 ]
then
 echo "need an arg to specify the sp"
 exit 0
fi

sleeptime=2s
# create initiator
hcli initiator  create --name 152 --iqn iqn.1994-05.com.redhat:6d4f296efb7e
sleep $sleeptime

# create volume
#hcli volume create --sp $1 --name v1 --size 2 --unit TB
#hcli volume create --sp $1 --name v2 --size 2 --unit TB
#hcli volume create --sp $1 --name v3 --size 2 --unit TB
for((i=1;i<=$2;i++));do
    hcli volume create --sp $1 --name v$i --size $3 --unit $4B
done;

sleep $sleeptime

# create vag 

# generate initiator
initiator=$(hcli initiator list |sed -n '4p' |awk -v FS="|" '{print $2}')
sleep $sleeptime

# generate volume list
hcli volume list --sp $1 | sed -n '4,6p' | awk -v FS="|" '{print $2}' > volume.txt
vlist=""
for i in `cat volume.txt`
do
 vlist="$vlist $i"
done
sleep $sleeptime

# create vag
hcli volume-access-group create --sp $1 --name vag --ilist $initiator --vlist $vlist
sleep $sleeptime

iscsiInit
