#!/bin/bash

#ftp://172.16.2.30/build/2.3.0/142-20231030/CentOS-Intel/hcdserver-2.3.0-142.el7.noarch.rpm
#ftp://172.16.2.30/build/2.3.0/142-20231030/CentOS-Intel/hcdserver-2.3.0-142.ob.el7.noarch.rpm
#hcdserver-2.3.0-142.el7.noarch.rpm

. common.sh

#get the latest date
fun1(){
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

VERSION=`sed -n '/VERSION/p' wbGetPkg.txt | awk -v FS="=" '{print $2}'`
BID=`sed -n '/BID/p' wbGetPkg.txt | awk -v FS="=" '{print $2}'`
OB=`sed -n '/OB/p' wbGetPkg.txt | awk -v FS="=" '{print $2}'`
PLATFORM=`sed -n '/PLATFORM/p' wbGetPkg.txt | awk -v FS="=" '{print $2}'`

FTP_URL='ftp://172.16.2.30/build'

build_folder=(`curl -s ${FTP_URL}/${VERSION}/ | grep "${BID}-" | awk '{print $9}' | awk -v FS="-" '{print $2}'`)
#echo ${build_folder[*]}
build_folder=$(getLatestDate ${build_folder[*]})
#echo $build_folder


:<<eof
download_url=${FTP_URL}/${VERSION}/${build_folder}/${PLATFORM}/
echo $download_url
if [ $OB == "YES" ];then
 OB2="ob."
elif [ $OB == "NO" ];then
 OB2=""
fi

buildprefix="hcdserver-$VERSION-$BID"

if [ $PLATFORM == "CentOS-Intel" ];then
 buildsubfix="el7.noarch.rpm"
else
 buildsubfix="el7.centos.noarch.rpm"
fi

buildname=${buildprefix}.${OB2}${buildsubfix}
echo $buildname

cd download
wget ${download_url}${buildname}

for i in `cat ../ips.txt`
do
 sudo scp $pkg_name root@$i:/home/hcd
done
eof
