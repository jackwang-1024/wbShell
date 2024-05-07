#!/bin/bash

. ./log.sh
. ./check_build_deb.sh
. ./check_env.sh
. ./reinstall.sh
. ./setup_cluster.sh

REDEPLOYED_LOG="$HCD_REDEPLOYED/reinstall.log"

check_parameter
config_sudo_privileges
check_osrelease
check_soft ssh openssh
check_soft expect expect
check_soft wget wget
get_inifile_info ${CLUSTERNAME}
cluster_os
get_buildpkg ${buildname} ${hostip} ${clusterOS}
redeploy_hstor
install_hcli ${Buildid} ${hcdversion}
modify_config_json ${MVIP}
sleep 600
setup_cluster ${MVIP} ${SVIP}
