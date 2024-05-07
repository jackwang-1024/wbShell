#!/usr/bin/python2
# -*- coding: utf-8 -*-
# @Time : 12/14/2021 10:56 AM
# @Author : haiwang
# @Site : 
# @File : remote_control.py
# @Software: PyCharm

import logging,sys,paramiko,time,random
import argparse
import time
import threading
from multiprocessing import Process
import os
import requests,json
from multiprocessing import Pool
import smtplib
#from email.mime.multipart import MIMEMultipart
#from email.mime.text import MIMEText

t=time.strftime("%Y%m%d%H%M", time.localtime())
logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')

# logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')
def detect_master(host):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(hostname=host, port=22, username='hcd',password='hcd')
        stdin, stdout, stderr = ssh.exec_command('sudo fio -filename=/dev/sdb -direct=1 -iodepth 1 -thread -rw=randrw -rwmixread=70 -ioengine=psync -bs=4k -size=500G -numjobs=50 -runtime=100 -group_reporting -name=4k_rand_r70w30' )

        stdout = stdout.read().decode()
        logging.warning("%s" %stdout)

        ssh.close()

    except Exception as e:
        logging.error("%s" % e)
        logging.error("plases cheack ssh info")
        ssh.close()
        exit()

def mutiple_detect():
    h = ['172.16.100.161','172.16.100.162', '172.16.100.163', '172.16.100.164', '172.16.100.165', '172.16.100.166', '172.16.100.167', '172.16.100.169', '172.16.100.170', '172.16.100.171']
    t1 = threading.Thread(target=detect_master, args=(h[0],))
    t2 = threading.Thread(target=detect_master, args=(h[1],))
    t3 = threading.Thread(target=detect_master, args=(h[2],))
    t4 = threading.Thread(target=detect_master, args=(h[3],))
    t5 = threading.Thread(target=detect_master, args=(h[4],))
    t6 = threading.Thread(target=detect_master, args=(h[5],))
    t7 = threading.Thread(target=detect_master, args=(h[6],))
    t8 = threading.Thread(target=detect_master, args=(h[7],))
    t9 = threading.Thread(target=detect_master, args=(h[8],))
    t10 = threading.Thread(target=detect_master, args=(h[9],))

    t1.start()
    t2.start()
    t3.start()
    t4.start()
    t5.start()
    t6.start()
    t7.start()
    t8.start()
    t9.start()
    t10.start()

    t1.join()
    t2.join()
    t3.join()
    t4.join()
    t5.join()
    t6.join()
    t7.join()
    t8.join()
    t9.join()
    t10.join()

if __name__ == '__main__':
    mutiple_detect()
