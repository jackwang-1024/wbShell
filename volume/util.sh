#! /bin/bash
source ./log.sh
VOLUME_PATH=/home/hcd/zoe_shell/volume
VOLUME_LOG_PATH=${VOLUME_PATH}/shell_volume.log
VOLUME_DISCOVER_PATH=${VOLUME_PATH}/volume_discover.txt
VOLUME_IQN_PATH=${VOLUME_PATH}/volume_iqn.txt
DISK_PATH=${VOLUME_PATH}/disk.txt
MOUNTPOINTS_PATH=${VOLUME_PATH}/mountpoints.txt
FILE_MD5=${VOLUME_PATH}/file_md5.txt
#define function to unmount and logout volumes
function logout_volumes(){
	echo -e "$(log_info) umount disks">>${VOLUME_LOG_PATH}
	sudo umount /mnt/*
	echo -e "$(log_info) logout volumes">>${VOLUME_LOG_PATH}
	sudo iscsiadm -m node -u
}
#define function to clear datas
function clear_datas(){
	if [[ -e volume_iqn.txt && -f volume_iqn.txt ]];then
		sudo rm -rf ./*.txt
	fi
}
#define function to discover volumes
#params:$1=svip;$2=volume number
function discover_volumes(){
	echo -e "$(log_info) discover volumes">>${VOLUME_LOG_PATH}
	echo -e $(sudo iscsiadm -m discovery -t st -p $1)>>${VOLUME_DISCOVER_PATH}
	echo -e "$(log_info) get volumes iqn">>${VOLUME_LOG_PATH}
	for((i=1;i<=$2;i++))
	do
		num=${i}
		product=$((2*num))
		echo -e $(cat volume_discover.txt|awk '{print $'${product}'}')>>${VOLUME_IQN_PATH}
	done
}
#define function to login volumes
function login_volumes(){
	echo -e "$(log_info) login volumes">>${VOLUME_LOG_PATH}
	iqnNum=$(cat volume_iqn.txt|wc -l)
	for((i=1;i<=${iqnNum};i++))
	do
		iqn=$(cat volume_iqn.txt|sed -n ''${i}'p')
		sudo iscsiadm -m node -T ${iqn} -l
	done
	echo -e "$(log_info) check if volumes login successfully">>${VOLUME_LOG_PATH}
	diskSum=$((${iqnNum}+6))
	echo -e $(lsblk|head -n ${diskSum}|tail -n ${iqnNum}|cut -d " " -f 1 )>>${DISK_PATH}
	diskNum=$(cat disk.txt|awk '{print NF}')
	for((i=1;i<=${diskNum};i++))
	do
		disk=$(cat disk.txt|awk '{print $'${i}'}')
		if [[ -n ${disk} ]];then
			printf "$(log_info) successfully login volume:%s\n" ${disk}|tee -a ${VOLUME_LOG_PATH}
		else
			echo -e "$(log_error) failed to login volumes\n"|tee -a ${VOLUME_LOG_PATH}
		fi
	done
}
#define function to format disks,format:ext2/ext3/ext4/xfs
#params:$1=format type
function format_disks(){
	echo -e "$(log_info) format raw disks">>${VOLUME_LOG_PATH}
	if [[ $1 == ext4 || $1 == ext3 || $1 == ext2 ]];then
        	for((i=1;i<=${diskNum};i++))
        	do
                	disk=$(cat disk.txt|awk '{print $'${i}'}')
                	sudo mkfs -t $1 /dev/${disk}
			exit=$?
			if [[ ${exit} -eq 0 ]];then
				echo -e "$(log_info) successfully format disk /dev/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
			else
				echo -e "$(log_error) failed to format disk /dev/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
			fi
        	done
	elif [[ $1 == xfs ]];then
        	for((i=1;i<=${diskNum};i++))
       		do
                	disk=$(cat disk.txt|awk '{print $'${i}'}')
               		sudo mkfs.$1 -f  /dev/${disk}
			exit=$?
			if [[ ${exit} -eq 0 ]];then
				echo -e "$(log_info) successfully format disk /dev/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
			else
				echo -e "$(log_error) failed to format disk /dev/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
			fi
       		 done
	else
        	printf "$(log_warn) diskFormat:%s does not exit\n" $1|tee -a ${VOLUME_LOG_PATH}
	fi
}
#define function to mount disks
function mount_disks(){
	echo -e "$(log_info) delete mountpoints">>${VOLUME_LOG_PATH}
	sudo rm -rf /mnt/*
	echo -e "$(log_info) create mountpoints">>${VOLUME_LOG_PATH}
	for((i=1;i<=${diskNum};i++))
	do
		disk=$(cat disk.txt|awk '{print $'${i}'}')
        	sudo mkdir -p /mnt/${disk}
		if [[ -e /mnt/${disk} && -d /mnt/${disk} ]];then
			echo -e "$(log_info) successfully create dir /mnt/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
			echo -e "$(log_info) mount disks">>${VOLUME_LOG_PATH}
			sudo mount /dev/${disk} /mnt/${disk}
			exit=$?
			if [[ ${exit} -eq 0 ]];then
				printf "$(log_info) successfully mount disk /dev/%s\n" ${disk}|tee -a ${VOLUME_LOG_PATH}
			else
				echo -e "$(log_error) failed to mount disk\n"|tee -a ${VOLUME_LOG_PATH}
			fi
		else

			echo -e "$(log_info) failed to create dir /mnt/${disk}\n"|tee -a ${VOLUME_LOG_PATH}
		fi
	done
}
#use dd tool to write data and calculate file md5 value
#params:$1=filename,$2=datasize
function dd_md5(){
	cd /mnt
	mountNum=$(ls|wc -l)
	echo -e $(ls)>${MOUNTPOINTS_PATH}
	for((i=1;i<=${mountNum};i++))
	do
		mountpoint=$(cat ${MOUNTPOINTS_PATH}|awk '{print $'${i}'}')
		echo -e "$(log_info) write $2M to /mnt/${mountpoint}/file$1">>${VOLUME_LOG_PATH}
		sudo dd if=/dev/urandom of=/mnt/${mountpoint}/file$1 bs=1M count=$2 oflag=direct
		cd /mnt/${mountpoint}
		if [[ -e file$1 && -f file$1 ]];then
			echo -e "$(log_info) calculate file$1 md5 value">>${VOLUME_LOG_PATH}
			sudo md5sum file$1|tee -a ${FILE_MD5}
		else
			echo -e "$(log_warn) file$1 does not exist"|tee -a ${VOLUME_LOG_PATH}
		fi
	done		
}
