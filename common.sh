#!/bin/bash

#get the latest date
#传入一个日期数组
getLatestDate(){
a=("$@")
for(( i=0;i<${#a[*]};i++ ));do
 if [ $i -eq 0 ];then
  latest=${a[$i]}
 elif [ $latest -lt ${a[$i]} ];then
  latest=${a[$i]}
 fi
done
echo $latest

}

