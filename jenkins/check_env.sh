#!/bin/bash
#!/usr/bin/expect

. ./log.sh

HCD_REDEPLOYED="/scratch/reinstall"
REDEPLOYED_LOG="$HCD_REDEPLOYED/log/reinstall.log"

#change sudo without password
function config_sudo_privileges(){
	echo "hcd ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/hcd >/dev/null 2>&1
	echo -e "$(log_info) config sudo privileges" | tee -a ${REDEPLOYED_LOG}
        grep -Ev '^$|^#' /etc/ssh/ssh_config | grep "StrictHostKeyChecking no" >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		echo "StrictHostKeyChecking no" | sudo tee -a /etc/ssh/ssh_config
		echo -e "$(log_info) config ssh StrictHostKeyChecking" | tee -a ${REDEPLOYED_LOG}
	else
		echo -e "$(log_info) no need to config ssh StrictHostKeyChecking" | tee -a ${REDEPLOYED_LOG}
	fi 
}

#confirm os release
function check_osrelease(){
	local localOS=`awk -F '=' '/^NAME/{print $2}' /etc/os-release` 
	if [[ ${localOS} =~ "Ubuntu" ]]; then 
		echo -e "$(log_info) the os-release: Ubuntu" | tee -a ${REDEPLOYED_LOG}
		systeminfo=${localOS}
	elif [[ ${localOS} =~ "CentOS Linux" ]]; then
		echo -e "$(log_info) the os-release: CentOS Linux" | tee -a ${REDEPLOYED_LOG}
		systeminfo=${localOS}
	else 
		echo -e "$(log_error) cannot recognize the os-release" | tee -a ${REDEPLOYED_LOG}
		exit 1
	fi
}

#check format and input of ip
function check_hostip(){
	if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OLD_IFS=$IFS
		IFS='.'
		ip=($1)
		IFS=${OLD_IFS}
		if [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]; then
			echo -e "$(log_info) $1 is correct" | tee -a ${REDEPLOYED_LOG}
		else
			echo -e "$(log_error) $1 is not correct" | tee -a ${REDEPLOYED_LOG}
			exit 2
		fi
	else
		echo -e "$(log_error) $1 format is not correct" | tee -a ${REDEPLOYED_LOG}
		exit 1
	fi
}

#check the network of the host
function check_network(){
	ping -c 1 www.baidu.com >/dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo -e "$(log_info) reach network successfully" | tee -a ${REDEPLOYED_LOG}
	else
		echo -e "$(log_warn) cannot reach network, please check your network" | tee -a ${REDEPLOYED_LOG}
		exit 1
	fi
}

#check the network between hosts
function check_host2host(){
	ping -c 1 $1 >/dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		echo -e "$(log_info) ping $1 successfully" | tee -a ${REDEPLOYED_LOG}
	else
		echo -e "$(log_warn) cannot reach host: $1, please check your network between hosts " | tee -a ${RDEPLOYED_LOG}
		exit 1
	fi
}

#check soft has been installed
#if not,install it
function check_soft(){
	which $1 &>/dev/null 
	if [[ $? -ne 0 ]];then
		#echo "install"
		#make a config to read different systeminfo list
 		check_network
		echo -e "$(log_info) start installing $1" | tee -a ${REDEPLOYED_LOG}
		if [[ ${systeminfo} =~ "Ubuntu" ]]; then 
			sudo apt install -y $2 >/dev/null 2>&1
		elif [[ ${systeminfo} =~ "CentOS Linux" ]]; then			
			sudo yum install -y $2 >/dev/null 2>&1
		fi
		which $1 &>/dev/null
		if [[ $? -ne 0 ]]; then
			echo -e "$(log_warn) failed to install $2, please install $2 manually" | tee -a ${REDEPLOYED_LOG} 
			exit 1		
		else
			echo -e "$(log_info) installed $2 successfully" | tee -a ${REDEPLOYED_LOG}
		fi
	else
		echo -e "$(log_info) $2 has been installed" | tee -a ${REDEPLOYED_LOG}
	fi
}
#check ssh without password
function check_authorized_keys(){
	###check old id_rsa
	cd /home/hcd/.ssh/
	#delete known_hosts
	rm -rf known_hosts
	if [[ -f "id_rsa.pub" ]]; then
		echo -e "$(log_info) id_rsa.pub has exist" | tee -a ${REDEPLOYED_LOG}
	else
		echo -e "$(log_info) id_rsa.pub didn't exist" | tee -a ${REDEPLOYED_LOG}
		echo -e "$(log_info) start generating the key" | tee -a ${REDEPLOYED_LOG}
		#ssh-keygen -t rsa
		expect -c "
		set timeout -1
		spawn ssh-keygen -t rsa
		expect { 
			\"*/home/hcd/.ssh/id_rsa\" {send \"\r\";exp_continue}
			\"*passphrase):\"	{send \"\r\";exp_continue}
			\"*again:\" {send \"\r\";exp_continue}
		eof	{exit 0;}
		}" >/dev/null 2>&1
	fi

	ssh $1@$2 -o PreferredAuthentications=publickey \
	-o StrictHostKeyChecking=no "whoami" >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then
		#sudo ssh-copy-id -i ~/.ssh/id_rsa.pub ${hostname}@${hostip[i]}
		expect -c "
		set timeout -1
		spawn ssh-copy-id -i /home/hcd/.ssh/id_rsa.pub $1@$2
		expect {
			\"*(yes/no)*\" {send \"yes\r\";exp_continue }
			\"*password:\" {send \"$3\r\";exp_continue }
			eof {exit 0} 
			}" >/dev/null 2>&1
		echo -e "$(log_info) scp keyssh to $2" | tee -a ${REDEPLOYED_LOG}
	else
		echo -e "$(log_info) local host to $2 has been configured " | tee -a ${REDEPLOYED_LOG}
	fi

}
