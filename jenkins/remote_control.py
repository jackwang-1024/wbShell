#!/usr/bin/python3
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
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


t=time.strftime("%Y%m%d%H%M", time.localtime())
logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S',filename='%s_performance.log' %t)

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
    for i in h:
        t=threading.Thread(target=detect_master, args=(i,))
        t.start()

    t.join()



if __name__ == '__main__':
    mutiple_detect()
    io = []
    aggrb = []
    minb = []
    maxb = []
    mint = []
    maxt = []
    with open('%s_performance.log' %t, 'r+') as f:
        for i in f.readlines():
            if "READ" in i:
                li = i.split(',')[0]
                io.append(li.split('=')[1])

                li = i.split(',')[1]
                aggrb.append(li.split('=')[1])

                li = i.split(',')[2]
                minb.append(li.split('=')[1])

                li = i.split(',')[3]
                maxb.append(li.split('=')[1])

                li = i.split(',')[4]
                mint.append(li.split('=')[1])

                li = i.split(',')[5]
                maxt.append(li.split('=')[1])

    for hlist in (io, aggrb, minb, maxb, mint, maxt):
        for i in range(len(hlist)):
            if 'KB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('KB/s'))
            elif 'MB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('MB/s')) * 1024
            elif 'GB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('GB/s')) * 1024 * 1024
            elif 'KB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('KB'))
            elif 'MB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('MB')) * 1024
            elif 'GB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('GB')) * 1024 * 1024
            elif 'msec' in hlist[i]:
                hlist[i] = float(hlist[i].strip('\n').strip('msec'))
            else:
                print('eeeeeee')
                hlist[i] = float(hlist[i].strip('sec'))
                print(hlist[i], "is not normal")
    all = []
    for hlist in (io, aggrb, minb, maxb, mint, maxt):
        total = 0
        for i in hlist:
            total = total + i
        all.append(total / (len(hlist)))
    logging.warning("READ统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all[0], all[1], all[2], all[3], all[4], all[5]))

    print(
        "READ统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all[0], all[1], all[2], all[3], all[4], all[5]))

    io = []
    aggrb = []
    minb = []
    maxb = []
    mint = []
    maxt = []
    with open('%s_performance.log' % t, 'r+') as f:
        for i in f.readlines():
            if "WRITE" in i:
                li = i.split(',')[0]
                io.append(li.split('=')[1])

                li = i.split(',')[1]
                aggrb.append(li.split('=')[1])

                li = i.split(',')[2]
                minb.append(li.split('=')[1])

                li = i.split(',')[3]
                maxb.append(li.split('=')[1])

                li = i.split(',')[4]
                mint.append(li.split('=')[1])

                li = i.split(',')[5]
                maxt.append(li.split('=')[1])

    for hlist in (io, aggrb, minb, maxb, mint, maxt):
        for i in range(len(hlist)):
            if 'KB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('KB/s'))
            elif 'MB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('MB/s')) * 1024
            elif 'GB/s' in hlist[i]:
                hlist[i] = float(hlist[i].strip('GB/s')) * 1024 * 1024
            elif 'KB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('KB'))
            elif 'MB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('MB')) * 1024
            elif 'GB' in hlist[i]:
                hlist[i] = float(hlist[i].strip('GB')) * 1024 * 1024
            elif 'msec' in hlist[i]:
                hlist[i] = float(hlist[i].strip('\n').strip('msec'))
            else:
                print('eeeeeee')
                hlist[i] = int(hlist[i].strip('sec'))
                print(hlist[i], "is not normal")
    all2 = []
    for hlist in (io, aggrb, minb, maxb, mint, maxt):
        total = 0
        for i in hlist:
            total = total + i
        all2.append(total / (len(hlist)))

    logging.warning(
        "WRITE统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all2[0], all2[1], all2[2], all2[3], all2[4], all2[5]))

    print(
        "WRITE统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all2[0], all2[1], all2[2], all2[3], all2[4], all2[5]))

    logging.warning(
        "总计统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均 mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all[0] + all2[0], all[1] + all2[1], all[2] + all2[2], all[3] + all2[3], all[4] + all2[4], all[5] + all2[5]))

    print(
        "总计统计如下 ： 平均 io为 %2.f ,平均 aggrb为 %2.f KB/s,平均 minb为 %2.f KB/s,平均 maxb为 %2.f KB/s,平均 mint为 %2.f msec ,平均 maxt为 %2.f msec" % (
        all[0] + all2[0], all[1] + all2[1], all[2] + all2[2], all[3] + all2[3], all[4] + all2[4], all[5] + all2[5]))