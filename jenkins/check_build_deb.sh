#!/bin/bash

. ./log.sh
. ./check_env.sh
. ./get-ftp.sh

#HCD_REDEPLOYED="/scratch/reinstall/"
REDEPLOYED_LOG="$HCD_REDEPLOYED/log/reinstall.log"
CONFIG_FILE="$HCD_REDEPLOYED/clusterinfo.ini"
Parameternum=$#
#echo ${Parameternum}
Parameter=($@)

function help_man(){
cat <<EOF
Usage: 
	sh reinstall.sh [-h] --clusterid CLUSTERID --buildid BUILDID --version VERSION --platform PLATFORM --obscure OBSCURE

Required arguments:
  -c CLUSTERID, --clusterid CLUSTERID The id of cluster to deploy
  -b BUILDID, --buildid BUILDID       The id of build to deploy
  -v VERSION, --version VERSION       The version of hstor
  -p PLATFORM, --platform PlATFORM    The platform to deploy (CentOS-AMD/CentOS-Intel)
  -o OBSCURE, --obscure OBSCURE       Whether install with obscure rpm

Optional argument:
	-h, --help                          Show help message 
EOF
}

#Check Clusterid && Buildid
function check_parameter(){
  if [[ ${Parameternum} -eq 0 ]]; then
		echo "error: too few arguments!"
		help_man
		exit 1
  elif [[ ${Parameternum} -ge 11 ]]; then
		echo "error: too more arguments!"
		help_man
		exit 2
  else
    ARGS=`getopt -o "c:b:v:p:h:o" -l "clusterid:,buildid:,version:,platform:,obscure:,help," -- "${Parameter[@]}"` &>/dev/null
    #echo ${ARGS}
    if [ $? != 0 ]; then
      echo "error to get arguments"
      help_man
      exit 3
    fi

    eval set -- "${ARGS}"
    #for i in "${Parameter[@]}";do
		#  	echo  $i
		#done

    for i in {0..10};do
      case ${Parameter[$i]} in
        -h | --help)
          help_man
          exit 0
          ;;
        -c | --clusterid)
          if [[ "${Parameter[$(($i+1))]}" =~ ^[0-9]*$ ]]; then
            Clusterid=${Parameter[$(($i+1))]}
            CLUSTERNAME=cluster${Clusterid}
          else
            echo "error: clusterid is not an integer"
            exit 4
          fi
          #echo ${Clusterid}
          ;;
        -b | --buildid)
          if [[ "${Parameter[$(($i+1))]}" =~ ^[0-9]*$ ]]; then
            Buildid=${Parameter[$(($i+1))]}
          else
            echo "error: buildid is not an integer"
            exit 5
          fi
          #echo ${Buildid}
          ;;
        -v | --version)
          version=${Parameter[$(($i+1))]}
          #echo ${version}
          ;;
			  -p | --platform)
				  platform=${Parameter[$(($i+1))]}
				  #echo ${platform}
				  ;;
			  -o | --obscure)
				  obscure=${Parameter[$(($i+1))]}
				  if [[ ${obscure} == "false" ]];then
					  ob=""
				  else
					  ob="ob."
				  fi
				  ;;
        -- )
          echo "don't recognize the parameter"
            help_man
            exit 6
            ;;
        * )
          #echo "error:Invalid argument"
          #help_man
          #exit 7
          continue
          ;;
      esac
        i=$(($i+2))
    done
  fi

}

#get info of inifile
function get_inifile_info(){
	if [ -f ${CONFIG_FILE} ]; then
		echo -e "$(log_info) read redeploy config file. " | tee -a ${REDEPLOYED_LOG}
		#Whether session exists
		local cluster=$1
		SessionResult=$(awk -F '[][]' '/\[.*]/{print $2}' ${CONFIG_FILE} | grep -w "${cluster}" )
		if [[ "${SessionResult}" != "" ]];then
			echo -e "$(log_info) read ${cluster} info." | tee -a ${REDEPLOYED_LOG}
			#get_inifile_info
			cd ${HCD_REDEPLOYED}
			touch redeploy_clusterinfo.ini
			#redirect clusterinfo
			awk "/\[${cluster}\]/{a=1}a==1"  ${CONFIG_FILE}|sed -e'1d' -e '/^$/d'  -e 's/[ \t]*$//g' -e 's/^[ \t]*//g' -e 's/[ ]/@G@/g' -e '/\[/,$d' >redeploy_clusterinfo.ini
			hostlist=$(awk -F '=' '/host/{print $2 }' redeploy_clusterinfo.ini )
			#array of host
			hostip=(${hostlist//\ /})
			host_num=${#hostip[@]}
			username=$(awk -F '=' '/username/{print $2; exit}' redeploy_clusterinfo.ini )
			password=$(awk -F '=' '/password/{print $2; exit}' redeploy_clusterinfo.ini )
			#hcdversion=$(awk -F '=' '/version/{print $2; exit}' redeploy_clusterinfo.ini )
			hcdversion=${version}
			MVIP=$(awk -F '=' '/mvip/{print $2; exit}' redeploy_clusterinfo.ini )
			SVIP=$(awk -F '=' '/svip/{print $2; exit}' redeploy_clusterinfo.ini )
			buildprefix=hcdserver-${hcdversion}-${Buildid}
			if [[ "${platform}" == "CentOS-Intel" ]];then
				buildsubfix=el7.noarch.rpm
			else 
				buildsubfix=el7.centos.noarch.rpm
			fi
			buildname=${buildprefix}.${ob}${buildsubfix}
			#echo ${buildname}
			for i in "${!hostip[@]}";do
				check_hostip ${hostip[i]}
				check_host2host ${hostip[i]}
				check_authorized_keys ${username} ${hostip[i]} ${password}
			done
		else
			echo -e "$(log_error) ${cluster} didn't exist!" | tee -a ${REDEPLOYED_LOG}
			exit 1
		fi
	fi
}


#get debbuild
function get_buildpkg(){
        local buildname=$1
        hostip=$2
        clusteros=$3
        platform=$4
        pwd=${clusteros:4:6}
        build_md5sum=${buildprefix}.md5sum
        full_pwd=${HCD_REDEPLOYED}/download/${platform}
        pkgname=`cd ${full_pwd} && ls | grep ${buildname} | grep -v "md5sum" ` >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
                #didn't find deb
                echo -e "$(log_warn) didn't find the current pkg in local host!"
                echo -e "$(log_info) start to find pkg in ftp!"
                download_build ${Buildid} ${hcdversion} ${platform} ${buildname} ${build_md5sum}
        else
                echo -e "$(log_info) find the pkg: ${pkgname} " | tee -a ${REDEPLOYED_LOG}
                ## check md5sum of local and then compare with ftp server

                md5sumfile=`cd ${full_pwd} && ls | grep ${buildname}.md5sum` >/dev/null 2>&1
                if [[ $? -ne 0 ]];then
                        # didn't find md5sum redownload all
                        echo -e "$(log_warn) didn't find md5sum of ${pkgname}" | tee -a ${REDEPLOYED_LOG}
                        echo -e "$(log_info) start to redownload pkg in ftp"
                        download_build ${Buildid} ${hcdversion} ${platform} ${buildname} ${build_md5sum}
                else
                        #echo ${md5sumfile}
                        cd ${full_pwd} && md5sum -c ${buildname}.md5sum | tee -a ${REDEPLOYED_LOG}
			echo $?
                        if [[ $? -ne 0 ]]; then
                                echo -e "$(log_error) check md5sum failed!!!" | tee -a ${REDEPLOYED_LOG}
                                echo -e "$(log_warn) exit due to md5 is inconsistent with ftp" | tee -a ${REDEPLOYED_LOG}
                                download_build ${Buildid} ${hcdversion} ${platform} ${buildname} ${build_md5sum}
                        else 
                                echo -e "$(log_info) complete to check md5sum, md5sum is consistent with ftp!" | tee -a ${REDEPLOYED_LOG}
                        fi
                fi
        fi
        echo -e "$(log_info) start to copy package to servers!!!" | tee -a ${REDEPLOYED_LOG}
        #checkpkgname=`cd ${full_pwd} && ls | grep ${buildname}` >/dev/null 2>&1
        for i in "${!hostip[@]}"; do
                #if local server without update_config.sh should copy file to the all hosts
                file_flag=`ssh ${username}@${hostip[i]} "ls /home/hcd/ | grep 'update_config.sh'"`
                if [[ ! ${file_flag} ]]; then
                        echo -e "$(log_info) the ${hostip[i]} without update_config.sh " | tee -a ${REDEPLOYED_LOG}
                        echo -e "$(log_info) scp update_config.sh to ${hostip[i]}" | tee -a ${REDEPLOYED_LOG}
                        scp /scratch/reinstall/update_config.sh ${username}@${hostip[i]}:/home/hcd/ >/dev/null 2>&1
                else
                        echo -e "$(log_info) the ${hostip[i]} with update_config.sh " | tee -a ${REDEPLOYED_LOG}
                fi
                echo -e "$(log_info) scp ${buildname} to ${hostip[i]}" | tee -a ${REDEPLOYED_LOG}
                scp ${full_pwd}/${buildname} ${username}@${hostip[i]}:/tmp >/dev/null 2>&1
                echo -e "$(log_info) scp ${buildname} to ${hostip[i]} successfully" | tee -a ${REDEPLOYED_LOG}
        done
}