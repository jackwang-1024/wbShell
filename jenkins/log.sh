#!/bin/bash

#timestamp + log_level
function format_date()
{
	date +"%Y-%m-%d %H:%M:%S,%3N"
}

function log_info()
{
	echo "[$(format_date)][INFO]"
}

function log_warn()
{
	echo "\033[33m[$(format_date)][WARN]\033[0m"
}

function log_error()
{
	echo "\033[31m[$(format_date)][ERROR]\033[0m"
}

