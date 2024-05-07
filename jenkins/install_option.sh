#!/bin/bash

. /scratch/reinstall/log.sh
. /scratch/reinstall/check_env.sh
. /scratch/reinstall/check_build_deb.sh
. /scratch/reinstall/reinstall_new.sh

echo "*******Please enter the number as prompted**********"
echo "*------1: reinstall hcdserver                      *"
echo "*------2: only download hcdserver rpm              *"
echo "*------3: exit                                     *"
echo "****************************************************"
read -p "#######Enter your number:" number

if [ $number -eq 1 ];then
serveral_initial
redeploy_hstor
elif [ $number -eq 2 ];then
serveral_initial
elif [ $number -eq 3 ];then
exit 0
else
echo "The number you entered is wrong. Please rerun the program"
exit 1
fi
