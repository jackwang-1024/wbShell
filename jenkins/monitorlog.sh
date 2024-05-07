#!/bin/bash

loglist="/var/log/message /var/log/syslog /var/log/hcd/archon/archon.log"

for logname in ${loglist}; do
	echo -e ${logname}
	# nohup sudo tail -fn0 ${logname}  | grep -o -i --line-buffered 'assert' >>/home/hcd/stage/${logname} 2>&1 &
	file_name=${logname:4:6}
	echo -e ${file_name}
	echo -e "/home/hcd/stage/"
	done

