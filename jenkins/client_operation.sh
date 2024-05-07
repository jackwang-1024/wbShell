#!/bin/bash

. ./log.sh
. ./

MKFS_LOG=/home/hcd/stage/mkfs.log

tear_iscsi_cache()
{
    echo "$(log_info) =================" | tee -a ${MKFS_LOG}
    echo "$(log_info) clean iscsi cache (centos)" | tee -a ${MKFS_LOG}
    sudo umount /mnt/*
    sleep 5
    sudo iscsiadm -m node -u
    sudo rm -rf /var/lib/iscsi/nodes/*
    sudo rm -rf /var/lib/iscsi/ifaces/*
    sudo rm -rf /var/lib/iscsi/send_targets/*
    echo "$(log_info) clean completion" | tee -a ${MKFS_LOG}
    #### ubuntu
    #### sudo rm -rf /etc/iscsi/nodes/*
    #### sudo rm -rf /etc/iscsi/send_targets/*
}

login_volumes()
{
    SVIP=$1
    echo "$(log_info) discovery ${SVIP}" | tee -a ${MKFS_LOG}
    sudo iscsiadm -m discovery -t st -p ${SVIP} | tee -a ${MKFS_LOG}
    sleep 5
    echo "$(log_info) login volumes"
    sudo iscsiadm -m node -l | tee -a ${MKFS_LOG}
    echo "$(log_info) login volumes successfully"
}

make_fs_ext4()
{
    diskname=$1
    echo "$(log_info) =================" | tee -a /home/hcd/stage/mkfs.log
    echo "$(log_info) start to make ext4 on ${diskname} " | tee -a ${MKFS_LOG}
    #sudo mkfs.ext4 -E nodiscard -m 0 -F /dev/${diskname} | tee -a ${MKFS_LOG}
    nohup sudo mkfs.ext4 -m 0 -F /dev/${diskname} | tee -a /home/hcd/stage/mkfs${diskname}.log &
    echo -e "$(log_info) completd ext4 format on ${diskname}" | tee -a ${MKFS_LOG}
    echo 
}

make_fs_xfs()
{
    drivename=$1
    echo "$(log_info) =================" | tee -a /home/hcd/stage/mkfs.log
    echo "$(log_info) start to make xfs on ${diskname} " | tee -a ${MKFS_LOG}
    sudo mkfs.xfs -K -f /dev/${diskname} 2>>${MKFS_LOG}
    #sudo mkfs.xfs -f /dev/${diskname} 2>>${MKFS_LOG}
    echo "$(log_info) completd xfs format on ${diskname}" | tee -a ${MKFS_LOG}
}


make_fs_list()
{
    disksize=$1
    disklist=$(lsblk | grep ${disksize} | awk '{print $1}' | xargs)
    for diskinfo in ${disklist[*]};do
        echo "${diskinfo}"
        make_fs_ext4 ${diskinfo} 
    done
}

tear_iscsi_cache
#login_volumes 192.168.201.204
#make_fs_list 100G

