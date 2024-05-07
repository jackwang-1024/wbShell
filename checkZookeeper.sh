#!/bin/bash

# check zookeeper status
# author wangbo
# date 2023-08-04

ip=$(ip a | grep 206 | awk '{print $2}' | awk -F "/" '{print $1}')
echo "My IP: "${ip}
sudo echo srvr | nc ${ip} 2181
