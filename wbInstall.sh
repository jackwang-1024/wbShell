#!/bin/bash

# reinstall manually
# author wangbo
# date 2023-09-04

#for i in $(cat ips.txt)
#do
#   ssh root@$i sudo rpm -qa | grep hcdserver
#done

LOG_PATH="/home/hcd/wb/wbreinstall.log"
user="hcd"

function redeploy_hstor(){
        echo -e "$(log_date) start to reinstall" | tee ${LOG_PATH}
        purge_hcdserver
        purge_db
        sleep 10
        db_config
        install_hcdserver ${buildname}
        sleep 30
        update_config
        echo -e "$(log_date) Finished the reinstall" | tee -a ${LOG_PATH}
}

purge_hcdserver(){
        for i in $(cat ips.txt)
        do
                echo "$(log_date) ${i} purge hcdserver"  | tee -a ${LOG_PATH}
               
                local purge_name=`ssh ${user}@${i} sudo rpm -qa | grep hcdserver`
                ssh ${user}@${i} sudo rpm -e ${purge_name} | tee -a ${LOG_PATH}
                sleep 10

                echo "$(log_date) ${i} purge hcdserver successfully"  | tee -a ${LOG_PATH}
        done
}

purge_db(){
        for i in $(cat ips.txt)
        do         
                echo -e "$(log_date) ${i} db purge"  | tee -a ${LOG_PATH}
                ssh ${user}@${i} "cd /usr/share/hcdinstall/scripts && sudo ./db_purge.sh" | tee -a ${LOG_PATH}
                echo -e "$(log_date) ${i} db purge successfully"  | tee -a ${LOG_PATH}
        done
}

db_config(){
        for i in $(cat ips.txt)
        do
                echo -e "$(log_date) ${i} db config" | tee -a ${LOG_PATH}
                ssh ${user}@${i} "cd /usr/share/hcdinstall/scripts && sudo ./db_config.sh" | tee -a ${LOG_PATH}
                echo -e "$(log_date) ${i} db config successfully" | tee -a ${LOG_PATH}
                sleep 30
        done
}

install_hcdserver(){
        for i in $(cat ips.txt)
        do
                echo -e "$(log_date) ${i} install hcdserver " | tee -a ${LOG_PATH}
		ssh ${user}@${i} "cd /home/hcd && sudo rpm -ivh hcdserver-2.3.0-157.el7.noarch.rpm" | tee -a ${LOG_PATH}
                echo -e "$(log_date) ${i} install hcdserver successfully" | tee -a ${LOG_PATH}
        done
}

update_config(){
        for i in $(cat ips.txt)
        do
                echo -e "$(log_date) ${i} update_config" | tee -a ${LOG_PATH}
                ssh ${user}@${i} "cd /home/hcd && sh update_config.sh" | tee -a ${LOG_PATH}
                echo -e "$(log_date) ${i} update_config successfully" | tee -a ${LOG_PATH}
        done
}

log_date(){
    date +"%Y-%m-%d %H:%M:%S,%3N"
}

redeploy_hstor
