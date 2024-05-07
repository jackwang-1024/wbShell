#!/bin/bash

hcli snapshot list --sp 4764bb5e-d621-4f7e-b492-e806280a00c8 -v d4240ab5-cc1a-4945-a7aa-b790e4a1ee76 | sed -n '4,9p' | awk -v FS="|" '{print $2,$3}' | sort -k2 | awk '{print $1}' > ss.txt


i=0
for line in `cat ss.txt`
do
 echo "rollback to s$i:  $line"
 hcli volume rollback --sp 4764bb5e-d621-4f7e-b492-e806280a00c8 -v d4240ab5-cc1a-4945-a7aa-b790e4a1ee76 -s $line
 md5sum /dev/sdb
 i=`expr $i + 1`
done
