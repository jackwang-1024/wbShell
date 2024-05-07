#!/bin/bash

. /scratch/reinstall/log.sh
. /scratch/reinstall/check_env.sh
. /scratch/reinstall/check_build_deb.sh

#HCD_REDEPLOYED="/scratch/reinstall/"
REDEPLOYED_LOG="$HCD_REDEPLOYED/log/reinstall.log"

cluster_os(){
	clusterOS=`ssh ${username}@${hostip[0]} "awk -F '=' '/^ID=/{print $2}' /etc/os-release"`
	if [[ ${clusterOS} =~ "ubuntu" ]]; then 
		echo -e "$(log_info) the cluster os-release: ubuntu" | tee -a ${REDEPLOYED_LOG}
	elif [[ ${clusterOS} =~ "centos" ]]; then
		echo -e "$(log_info) the cluster os-release: centos" | tee -a ${REDEPLOYED_LOG}
	else 
		echo -e "$(log_error) cannot recognize the cluster os-release" | tee -a ${REDEPLOYED_LOG}
		exit 1
	fi
}

purge_hcdserver(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} purge hcdserver"| tee -a ${REDEPLOYED_LOG}
		if [[ ${clusterOS} =~ "ubuntu" ]]; then
			ssh ${username}@${hostip[i]} "sudo dpkg -P hcdserver || true" >>${REDEPLOYED_LOG}
		elif [[ ${clusterOS} =~ "centos" ]]; then
			local purge_name=`ssh ${username}@${hostip[i]} "sudo rpm -qa | grep hcdserver"`
			ssh ${username}@${hostip[i]} "sudo rpm -e ${purge_name} || true" >>${REDEPLOYED_LOG}
                        sleep 10
		fi
		echo -e "$(log_info) ${hostip[i]} purge hcdserver successfully"| tee -a ${REDEPLOYED_LOG}	
	done
}

purge_db(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} db purge"| tee -a ${REDEPLOYED_LOG}
		ssh ${username}@${hostip[i]} "cd /usr/share/hcdinstall/scripts && sudo ./db_purge.sh"| tee -a ${REDEPLOYED_LOG}
  		echo -e "$(log_info) ${hostip[i]} db purge successfully"| tee -a ${REDEPLOYED_LOG}
	done
}

db_config(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} db config"| tee -a ${REDEPLOYED_LOG}
		ssh ${username}@${hostip[i]} "cd /usr/share/hcdinstall/scripts && sudo ./db_config.sh" >>${REDEPLOYED_LOG}
		echo -e "$(log_info) ${hostip[i]} db config successfully"| tee -a ${REDEPLOYED_LOG}
                sleep 30
	done
}

install_hcdserver(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} install hcdserver "| tee -a ${REDEPLOYED_LOG}
		if [[ ${clusterOS} =~ "ubuntu" ]]; then
			ssh ${username}@${hostip[i]} "cd /tmp && sudo dpkg -i $1">>${REDEPLOYED_LOG}			
		elif [[ ${clusterOS} =~ "centos" ]]; then
			ssh ${username}@${hostip[i]} "cd /tmp && sudo rpm -ivh $1">>${REDEPLOYED_LOG}
		fi		
		echo -e "$(log_info) ${hostip[i]} install hcdserver successfully"| tee -a ${REDEPLOYED_LOG}
	done
}

update_config(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} update_config" | tee -a ${REDEPLOYED_LOG}
		ssh ${username}@${hostip[i]} "cd /home/hcd && sh update_config.sh" | tee -a ${REDEPLOYED_LOG}
		echo -e "$(log_info) ${hostip[i]} update_config successfully" | tee -a ${REDEPLOYED_LOG}
	done
}

tear_down(){
	for (( i = 0; i < ${host_num}; i++ )); do
		echo -e "$(log_info) ${hostip[i]} clean" | tee -a ${REDEPLOYED_LOG}
		echo -e "$(log_info) ${hostip[i]} start to delete deb " | tee -a ${REDEPLOYED_LOG}
		ssh ${username}@${hostip[i]} "cd /tmp && sudo rm -rf $1" >> ${REDEPLOYED_LOG}
		echo -e "$(log_info) ${hostip[i]} clean successfully" | tee -a ${REDEPLOYED_LOG}
	done
	echo -e "$(log_info) local host start to clean" | tee -a ${REDEPLOYED_LOG}
  	cd ${HCD_REDEPLOYED} && sudo rm -rf redeploy_clusterinfo.ini
  	echo -e "$(log_info) local host clean successfully" >> ${REDEPLOYED_LOG}
  	echo -e "\n\n$(log_info) finish reinstall" | tee -a ${REDEPLOYED_LOG}
}

function redeploy_hstor(){
        echo -e "\n\n$(log_info) start to reinstall ${CLUSTERNAME}" | tee -a ${REDEPLOYED_LOG}
	purge_hcdserver
	purge_db
        sleep 10
	db_config
	install_hcdserver ${checkpkgname}
	update_config
	tear_down ${pkgname}
        install_finish_date=`date +"%Y%m%d_%H%M%S"`
        echo -e "\n\n$(log_info) End" | tee -a ${REDEPLOYED_LOG}
        cd ${HCD_REDEPLOYED}/log && mv reinstall.log reinstall_${install_finish_date}_${CLUSTERNAME}.log
}

function serveral_initial(){
	check_parameter
	config_sudo_privileges
	check_osrelease
	check_soft ssh openssh
	check_soft expect expect 
        check_soft wget wget
	get_inifile_info ${CLUSTERNAME}
	cluster_os
	get_buildpkg ${buildname} ${hostip} ${clusterOS}
#	redeploy_hstor
}

