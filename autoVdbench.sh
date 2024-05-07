#!/bin/bash

#source /etc/profile
aa(){
limit=3
log=/home/hcd/wb/vd.log
currentUsedSpace=$(hcli storage-pool list | sed -n '4p' | awk -v FS="|" '{print $14}' | awk '{print $1}' | awk -v FS="." '{print $1}')
#b=999
#sleep 5s
date=`date`
#echo "[$date] b: ${b}" | tee -a $log
echo "[$date]currentUsedSpace: ${currentUsedSpace}" | tee -a $log

:<<eof
if [ $currentUsedSpace -ge $limit ]
then
echo "[$date]currentUsedSpace: ${currentUsedSpace} , greater than or eqeal to $limit , so kill the vdebench process! " | tee -a $log
ps -ef | grep vdb | sed -n '1,2p' | awk '{print $2}' > vd.txt
for i in `cat vd.txt`
do
 sudo kill -9 $i
done

fi

eof
}

while((1<2))
do
 aa
 sleep 10s
done
