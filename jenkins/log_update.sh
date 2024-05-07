#!/bin/bash

pwd_log=$1

#timestamp + log_level
function format_date()
{
	date +"%Y-%m-%d %H:%M:%S,%3N"
}

function log_info()
{
	info_message=$1
	echo -e "[$(format_date)][INFO] ${info_message}" | tee -a ${pwd_log}
}

function log_warn()
{
	warn_message=$1
	echo -e "\033[33m[$(format_date)][WARN]" ${warn_message} "\033[0m" | tee -a ${pwd_log}
}

function log_error()
{
	error_message=$1
	echo -e "\033[31m[$(format_date)][ERROR]" ${error_message} "\033[0m" | tee -a ${pwd_log}
}

