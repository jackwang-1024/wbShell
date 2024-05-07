#!/bin/bash

. ./log.sh

#ftp://172.16.2.30/build/2.1.0/59-20210527/CentOS-Intel/hcdserver-2.1.0-59.el7.noarch.rpm
#ftp://172.16.2.30/build/2.2.0/141-20220805/CentOS-AMD/hcdserver-2.2.0-141.el7.centos.noarch.rpm
FTP_URL='ftp://172.16.2.30/build'
#FTP_FOLDER=${FTP_URL}
#DOWN_URL=${FTP_URL}/${hcdversion}/${buildid}-*/CentOS-Intel/hcdserver-*.rpm
DOWN_LOG=/scratch/reinstall/down_from_ftp.log

download_build(){
    build_ID=$1
    build_version=$2
    build_platform=$3
    build_name=$4
    build_md5sum=$5
    build_folder=$(curl -s ${FTP_URL}/${build_version}/ | grep " ${build_ID}-" | awk -F ' ' '{print $9}')
    if [[ ${build_folder} == "" ]]; then
	    echo -e "$(log_error) didn't find the build folder in ftp server" | tee -a ${DOWN_LOG}
     	echo -e "$(log_warn) please check build id!" | tee -a ${DOWN_LOG}
      exit 1
    else
      echo -e "$(log_info) found the build foloder in ftp server."
    fi
    down_url=${FTP_URL}/${build_version}/${build_folder}/${build_platform}/
    echo ${down_url}
    hcli_build=$(curl -s $down_url | grep "hcdcli-" | awk -F ' ' '{print $9}')
    #build_name=$(curl -s $down_url | grep "hcdserver-" | grep -v "md5sum" | awk -F ' ' '{print $9}')
    echo ${hcli_build}
    echo ${build_name}
    if [[ ${build_name} == " " ]]; then
        #do not find the build
        echo -e "$(log_error) didn't find the build in ftp server" | tee -a ${DOWN_LOG}
        echo -e "$(log_warn) please check the build id exit!!!" | tee -a ${DOWN_LOG}
        exit 2
    else
        #find the build 
        echo -e "$(log_info) download from ftp" | tee -a ${DOWN_LOG}
        cd /scratch/reinstall/download/${build_platform}
        wget -nc ${down_url}${build_name}
        echo -e "$(log_info) download [${build_name}] successfully!" | tee -a ${DOWN_LOG}
        single_build_md5sum=${build_name}.md5sum
        wget -nc ${down_url}${build_md5sum}
        grep ${build_name} ${build_md5sum} | tee -a ${single_build_md5sum}
        echo -e "$(log_info) download [${build_md5sum}] successfully!" | tee -a ${DOWN_LOG}
        wget -nc ${down_url}${hcli_build}
        echo -e "$(log_info) download [${hcli_build}] successfully!" | tee -a ${DOWN_LOG}
    fi
    #check md5sum
    md5sum -c ${single_build_md5sum} | tee -a ${DOWN_LOG}
    if [[ $? -ne 0 ]]; then
        echo -e "$(log_error) check md5sum failed!!!" | tee -a ${DOWN_LOG}
        echo -e "$(log_warn) exit due to md5 is inconsistent with ftp" | tee -a ${DOWN_LOG}
        exit 3
    else 
	echo -e "$(log_info) complete to check md5sum, md5sum is consistent with ftp!" | tee -a ${DOWN_LOG}
        rm ${single_build_md5sum}
    fi   
}