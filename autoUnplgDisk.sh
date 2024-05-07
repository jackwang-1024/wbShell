#!/bin/bash

a=(0000:d9:00.0 0000:da:00.0 0000:db:00.0)
echo ${a[@]}

echo ${#a[@]}

echo "method1"
for((i=0;i<${#a[@]};i++))
do
 echo ${a[$i]}
 echo "date;echo 1 > /sys/bus/pci/devices/${a[$i]}/remove"
 sleep 60s
done

:<<eof
echo "method2"
j=0
while(( j<${#a[@]} ))
do
 echo ${a[$j]}
 j=`expr $j + 1`
done

echo "method3"
for k in ${a[@]}
do
 echo $k
done
eof
