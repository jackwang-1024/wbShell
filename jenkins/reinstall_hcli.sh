#!/bin/bash

. ./log.sh
. ./check_build_deb.sh

HCLI_INSTALL_LOG="/scratch/reinstall/install_hcli.log"
RPM_DIR="/scratch/reinstall/download"

install_hcli(){
new_build=$1
hcli_version=$2
python_version=`sudo python --version | awk -F ' ' '{print $2}'| awk -F '.' '{print $1}'`
which pip &>/dev/null
if [[ $? -ne 0 ]];then
	echo -e "$(log_error) the local host doesn't install pip, please install pip manually!"
	exit 1
fi
if [[ ${python_version} == 2 ]]; then
	new_hcli=hcdcli-${hcli_version}b1-${new_build}.el7.noarch.rpm
	echo "${new_hcli}"
	echo -e "$(log_info) check old version of hcli"
	old_hcli=$(sudo rpm -qa | grep hcdcli)
	if [[ $? -eq 0 ]];then
	    echo -e "$(log_info) remove old version of hcli" | tee -a ${HCLI_INSTALL_LOG}
	    sudo rpm -e ${old_hcli}
	else 
	    echo -e "$(log_info) there is no old hcli"
	fi
	check_hcli_rpm=$(ls ${RPM_DIR} | grep ${new_hcli})
	if [[ $? -ne 0 ]];then
	    echo -e "$(log_error) there is no installation pkg, please verify the version or pkg!"
	    exit 1
	else
	    echo -e "$(log_info) install new version of hcli" | tee -a ${HCLI_INSTALL_LOG}
	    sudo rpm -ivh ${RPM_DIR}/${new_hcli}
	    echo -e "$(log_info) complete new version of hcli installation" | tee -a ${HCLI_INSTALL_LOG}
	fi
else
	echo -e "$(log_error) the local host doesn't use python2"
fi
}

modify_config_json(){
MVIP=$1
echo -e "$(log_info) modify mvip in config.json of hcli" | tee -a ${HCLI_INSTALL_LOG}
previous_mvip=$(cat /usr/share/hcdserver/hcdcli/config.json | grep -i "ip" | awk -F '"' '{print $4}')
echo -e "$(log_info) previous mvip is ${previous_mvip}"
sudo sed -i 's/'"${previous_mvip}"'/'"${MVIP}"'/g' /usr/share/hcdserver/hcdcli/config.json
echo -e "$(log_info) change mvip successfully!" | tee -a ${HCLI_INSTALL_LOG}
}

