#!/bin/bash

# check md5
# author wangbo
# date 2023-10-27

# $1 sp id
# $2 volume id
# $3 sdb
. log.sh

touch checkMd5.log
echo "" > checkMd5.log
log=checkMd5.log

touch md5.log
echo "" > md5.log
md5file=md5.log

path=/dev/$3

for((i=0;i<=5;i++))
do
 if [ $i -gt 0 ]
 then
    echo "$(log_info)start to dd 1g" >> $log
    dd if=/dev/urandom of=$path bs=1M count=1024 oflag=direct
 fi 
  echo "$(log_info)start to create snapshot s$i" >> $log
  hcli snapshot create --sp $1 -v $2 --name s$i
  echo "$(log_info)start to generate md5 of s$i" >> $log
  md5=$(md5sum $path)
  # md5sum $path | tee -a $md5file
  md5Arr[${i}]=$md5
  echo "$(log_info)has generated the md5 of s$i : $md5" >> $log
  echo $md5 | tee -a $md5file
  echo s$i >> $md5file
done


echo "===begin rollback and checkmd5==="
hcli snapshot list --sp $1 -v $2 | sed -n '4,9p' | awk -v FS="|" '{print $2,$3}' | sort -k2 | awk '{print $1}' > ss.txt


i=0
for line in `cat ss.txt`
do
 echo "rollback to s$i"
 hcli volume rollback --sp $1 -v $2 -s $line
 md5_b=$(md5sum $path)
 echo "expected md5 of s$i: ${md5Arr[$i]}"
 echo "actual   md5 of s$i: ${md5_b}"
 if [ ${md5Arr[$i]} -eq ${md5_b} ]
 then
   echo "md5 of $i is consistent"
 else
   echo "md5 of $i is inconsistent"
 fi
 i=`expr $i + 1`
done





