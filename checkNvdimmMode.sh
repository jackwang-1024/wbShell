##! /bin/bash

# check nvdimm mode
# author wangbo
# date 2023-08-04


cat /var/log/hcd/archon/archon.log | tail -n 1 | grep "Archon cannot start because DEVDAX Nvdimm mode is incorrect, aborting"
result=$?
echo ${result}
if [ ${result} -eq 0 ];then
  sudo ndctl list -N
  sudo ndctl create-namespace --mode devdax --map dev -e namespace0.0 -a 4k -f
  date;sudo service hcdadmin start
fi

:<<EOF
echo "bbb"
echo 'ccc'
EOF
