#!/bin/bash

# check zookeeper status
# author wangbo
# date 2023-08-04

sleeptime=2s

iscsiInit(){
#ipv4
ip=$(hcli storage-pool list | sed -n '4p' | awk -v FS='|' '{print $15}')
#ipv6
#ip=$(hcli storage-pool list | sed -n '4p' | awk -v FS='|' '{print $16}')

:<<eof
echo "sudo iscsiadm -m session -P 1"
sudo iscsiadm -m session -P 1
eof


echo "sudo iscsiadm -m node -u"
sudo iscsiadm -m node -u
sleep $sleeptime

echo "sudo iscsiadm -m discovery -t st -p ${ip}"
sudo iscsiadm -m discovery -t st -p ${ip}
sleep $sleeptime

echo "sudo iscsiadm -m node -l -p ${ip}"
sudo iscsiadm -m node -l -p ${ip}

:<<eof
echo "sudo iscsiadm -m session -P 1"
sudo iscsiadm -m session -P 1
eof
}

#iscsiInit
