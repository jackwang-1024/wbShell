#!/bin/bash

format_date()
{
	date +"%Y-%m-%d %H:%M:%S,%3N"
}

log_info()
{
	echo "[$(format_date)][INFO]"	
}



