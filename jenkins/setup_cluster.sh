#!/bin/bash

. ./log.sh
. ./check_build_deb.sh

InitiatorName150=iqn.1994-05.com.redhat:38ca6f2ea534
InitiatorName152=iqn.1994-05.com.redhat:8135d6d98eba
SETUP_LOG="/scratch/reinstall/log/setup_cluster.log"
RPM_DIR="/scratch/reinstall/download"

create_cluster(){
SVIP=$1
CLUSTER_STATE=$(hcli cluster list | awk -F '|' '{print $11}' | sed -r '/^\s*$/d' | tail -n +2 | xargs)
if [[ $CLUSTER_STATE == '' ]]; then
    CLUSTER_NAME=$(strings /dev/urandom |tr -dc A-Z0-9 | head -c10 | xargs)
    echo -e "$(log_info) create cluster ${CLUSTER_NAME} " | tee -a ${SETUP_LOG}
    hcli cluster create --name ${CLUSTER_NAME} --size 3 --rf 3 --svip ${SVIP} | tee -a ${SETUP_LOG}
else
    echo -e "$(log_info) cluster has been created and cluster state is [$CLUSTER_STATE]" | tee -a ${SETUP_LOG}
fi

sleep 30
CLUSTER_ID=$(hcli cluster list | awk -F '|' '{print $2}' | sed -r '/^\s*$/d' | tail -n +2 | xargs)

ALL_HOSTS='True'
HOST_ID=$(hcli host list | awk -F '|' '{print $2}' | sed -r '/^\s*$/d' | tail -n +2 | xargs)
for ID in ${HOST_ID[*]}; do
    if hcli host list | egrep "$ID.*$CLUSTER_ID" >/dev/null 2>&1 ; then
        echo -e "$(log_info) [$ID] has already joined cluster" | tee -a ${SETUP_LOG}
    else
        ALL_HOSTS='False'
    fi
done

if [[ $ALL_HOSTS == 'False' ]]; then
    echo -e "$(log_info) hosts are joining cluster [$CLUSTER_ID]"| tee -a ${SETUP_LOG}
    hcli host join -c $CLUSTER_ID | tee -a ${SETUP_LOG}
fi
}

create_vol_4k(){
VOL_NUM=$1
for (( i=1;i<${VOL_NUM};i++ )); do
    VOL_NAME=yaotest${i}
    hcli volume create -c $CLUSTER_ID --name ${VOL_NAME} --size 100 --unit GB | tee -a ${SETUP_LOG}
    echo -e "$(log_info) create volume ${VOL_NAME} successfully" | tee -a ${SETUP_LOG}
done
}

create_vol_512B(){
VOL_512_NUM=$1
for (( i=1;i<${VOL_512_NUM};i++ )); do
    VOL_512B_NAME=rdm${i}
    hcli volume create -c $CLUSTER_ID --name ${VOL_512_NUM} --bs 512 --size 1024 --unit GB | tee -a ${SETUP_LOG}
    echo -e "$(log_info) create volume ${VOL_512_NUM} successfully" | tee -a ${SETUP_LOG}
done
}

create_ini(){
NAME=$1
IQN=$2
hcli initiator create --iqn ${IQN} --name ${NAME} | tee -a ${SETUP_LOG}
echo -e "$(log_info) create iqn ${IQN} successfully" | tee -a ${SETUP_LOG}
}

create_vag(){
VLIST=$(hcli volume list  -c ${CLUSTER_ID} | awk -F '|' '{print $2}' | sed -r '/^\s*$/d'| tail -n +2| xargs)
ILIST=$(hcli initiator list | awk -F '|' '{print $2}' | sed -r '/^\s*$/d'| tail -n +2| xargs)
VAG_NAME=$(strings /dev/urandom |tr -dc A-Z0-9 | head -c10 | xargs)
hcli volume-access-group create -c ${CLUSTER_ID} --name ${VAG_NAME} --ilist ${ILIST} --vlist ${VLIST} | tee -a ${SETUP_LOG}
echo -e "$(log_info) create vag ${VAG_NAME} successfully" | tee -a ${SETUP_LOG}
}

delete_vag(){
VAG_ID=$(hcli volume-access-group list -c ${CLUSTER_ID} | grep ${VAG_NAME}| awk -F '|' '{print $2}' | xargs)
hcli volume-access-group delete -c ${CLUSTER_ID} --id ${VAG_ID} | tee -a ${SETUP_LOG}
echo -e "$(log_info) delete vag ${VAG_NAME} successfully!" | tee -a ${SETUP_LOG}
}

delete_volume(){
VOL_GREP=$1
VLIST=$(hcli volume list  -c ${CLUSTER_ID} | grep "${VOL_GREP}" | awk -F '|' '{print $2}' | sed -r '/^\s*$/d'| tail -n +1| xargs)
for vol in ${VLIST[*]}; do
    hcli volume delete -c ${CLUSTER_ID} -v ${vol}
done
}

setup_cluster(){
    cluster_mvip=$1
    cluster_svip=$2
#    get_inifile_info
    modify_config_json ${cluster_mvip}
    sleep 5
    create_cluster ${cluster_svip}
    sleep 6
    create_vol_4k 4
#    delete_volume pvc
#    create_vol_512B 25
    create_ini 150 ${InitiatorName150}
#    create_ini 152 ${InitiatorName152}
    create_vag     
}

create_vol_512B 11
