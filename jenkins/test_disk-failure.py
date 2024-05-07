#!/usr/local/bin/python3
# -*- coding:utf-8 -*-
__author__ = 'HCD'
__date__ = '10/11/2021 10:02 AM'

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
logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S',filename='%s_disk_failure.log' %t)

# logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')
def config():
    parser = argparse.ArgumentParser(description='service failure in cluster')
    parser.add_argument('--cluster', type=int, required=True, help='which cluster ')
    parser.add_argument('--host', type=str, required=True, choices=['1','2'], help='disk failure in host'
                                                                                                             '1:  satrt 1 host disks failure,'
                                                                                                             '2:  satrt 2 host disks failure'
                        )
    parser.add_argument('--disk', type=int, required=False,default=1,
                        help='每台host拔几块盘，，默认为1'

                        )
    parser.add_argument('--times', type=int, required=True, help='setting  the value of wating time (senconds) ,then plug disk'

                        )

    args = parser.parse_args()
    return args

def cluster_info(cluster_number):
    with open('clusterinfo.txt', 'r') as f:
        ff = f.read().split()
        dict={}
        for i in range(0, len(ff)):
            try:
                if '[cluster' + str(cluster_number) + ']' == ff[i]:
                    dict['host0'] = ff[i + 1].split('=')[1]
                    dict['host1'] = ff[i + 2].split('=')[1]
                    dict['host2'] = ff[i + 3].split('=')[1]
                    dict['mvip'] = ff[i + 4].split('=')[1]
                    dict['svip'] = ff[i + 5].split('=')[1]
                    dict['username'] = ff[i + 6].split('=')[1]
                    dict['password'] = ff[i + 7].split('=')[1]
                    dict['version'] = ff[i + 8].split('=')[1]
                    break
            except:
                logging.error("no cluster info find, please modify clusterinfo.txt")
                exit()
    return dict

def get_token():
    requests.packages.urllib3.disable_warnings()
    headers = {'Connection': 'keep-alive',
               'Content-Length': '68',
               'Accept': 'application/json, text/plain, */*',
               'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36',
               'Content-Type': 'application/x-www-form-urlencoded',
               'Sec-Fetch-Site': 'same-origin',
               'Sec-Fetch-Mode': 'cors',
               'Sec-Fetch-Dest': 'empty',
               'Accept-Encoding': 'gzip, deflate, br',
               'Accept-Language': 'zh-CN,zh;q=0.9',
               'authorization': 'Basic aGNkLWNsaWVudDpoY2Qtc2VjcmV0'
               }
    data1 = {"grant_type": "password",
             "username": "admin",
             "password": "Hello123"
             }
    r = requests.session()
    res = r.post(url='https://%s:8443/oauth/token' %mvip, data=data1, headers=headers, verify=False)

    if res.status_code != 200:
        data1 = {"grant_type": "password",
                 "username": "admin",
                 "password": "Welc0me!01"
                 }
        r = requests.session()
        res = r.post(url='https://%s:8443/oauth/token' %mvip, data=data1, headers=headers, verify=False)
        d1 = json.loads(res.text)
        token = d1['access_token']
        if res.status_code != 200:
            logging.error("can not login,please check password")
            exit()

    else:
        d1 = json.loads(res.text)
        token = d1['access_token']
        headers = {'Connection': 'keep-alive',
                   'Content-Length': '68',
                   'Accept': 'application/json, text/plain, */*',
                   'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36',
                   'Content-Type': 'application/json',
                   'Sec-Fetch-Site': 'same-origin',
                   'Sec-Fetch-Mode': 'cors',
                   'Sec-Fetch-Dest': 'empty',
                   'Accept-Encoding': 'gzip, deflate, br',
                   'Accept-Language': 'zh-CN,zh;q=0.9',
                   'authorization': 'Bearer  %s' % token
                   }
        return headers



def get_host():
    headers = get_token()
    url='https://%s:8443/v1/clusters?clusterType=regular' %mvip
    r = requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    try:
        for i in json.loads(res.text)['data']:
            if i['state']=='ONLINE':
                clusterId=i['clusterId']
    except Exception as e:
        logging.error("no online cluster find,please cheack")
        exit()

    url='https://%s:8443/v1/hosts?clusterId=%s&?filter=%%7B%%7D' %(mvip,clusterId)

    r = requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    host_Info = {}


    try:
        for i in json.loads(res.text)['data']:

            disk_info=[]
            url = 'https://%s/v1/disks/by-host/%s' % (mvip,i['hostId'])

            r = requests.session()
            res2 = r.get(url=url, headers=headers, verify=False)
            managementAddress=i['managementAddress']


            if host == '1':
                if managementAddress == choice_host:

                    for j in json.loads(res2.text)['data']:
                        disk_info.append([j['deviceNodeName'], j['mountPoint']])
                        host_Info[managementAddress] = disk_info
                    print("%s 有 %s 块磁盘:  磁盘信息为：%s" %(managementAddress,len(host_Info[managementAddress]),disk_info))
                    logging.warning("%s 有 %s 块磁盘:  磁盘信息为：%s" %(managementAddress,len(host_Info[managementAddress]),disk_info))

                    try:
                        choice_disk = random.sample(disk_info, disk)

                    except Exception as e:
                        logging.error("盘不够你拔呢。")
                        exit()



                    host_Info[managementAddress] = choice_disk
                    print("%s 做diskfailure的磁盘为： %s" %(managementAddress,choice_disk))
                    logging.warning("%s 做diskfailure的磁盘为：%s" %(managementAddress,choice_disk))

            else:
                if managementAddress != choice_host:

                    for j in json.loads(res2.text)['data']:
                        disk_info.append([j['deviceNodeName'], j['mountPoint']])
                        host_Info[managementAddress] = disk_info
                    print("%s 有 %s 块磁盘:  磁盘信息为：%s" %(managementAddress,len(host_Info[managementAddress]),disk_info))
                    logging.warning(
                        "%s 有 %s 块磁盘:  磁盘信息为：%s" % (managementAddress, len(host_Info[managementAddress]), disk_info))

                    try:
                        choice_disk = random.sample(disk_info, disk)

                    except Exception as e:
                        logging.error("盘不够你拔呢。")
                        exit()

                    host_Info[managementAddress] = choice_disk
                    print("%s 做diskfailure的磁盘为： %s" %(managementAddress,choice_disk))
                    logging.warning("%s 做diskfailure的磁盘为：%s" %(managementAddress,choice_disk))



    except Exception as e:
        logging.error("get disk failed %s" % e)
        print(e)
        exit()


    print("将做diskFailure的信息为： %s" %host_Info)
    logging.warning("将做diskFailure的信息为： %s" %host_Info)


    return host_Info
def unplug_disk():
    port_info= {}


    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())


    for i in host_Info.keys():
        disk_info = []
        try:
            transport = paramiko.Transport(i, 22)
            transport.connect(username=dict['username'], password=dict['password'])
            ssh.connect(hostname=i, port=22, username=dict['username'], password=dict['password'])
            sftp = paramiko.SFTPClient.from_transport(transport)
            sftp.put('poweroff_disk.sh', 'poweroff_disk.sh')

            for j in host_Info[i]:
                stdin, stdout, stderr = ssh.exec_command('ls -l /sys/block/%s' % j[0])
                stdout = stdout.read().decode()
                print(stdout)
                logging.warning("%s" % stdout)
                port = stdout.split('/')[-5]
                disk_info.append([port, j[0],j[1]])

                port_info[i] = disk_info
                stdin, stdout, stderr = ssh.exec_command(
                    'sudo /bin/bash  /home/hcd/poweroff_disk.sh %s' % j[0])
                stdout = stdout.read().decode()
                print(stdout)
                logging.warning("%s" % stdout)

                logging.warning("在主机 %s 上已经将盘 %s 拔出,原先的mount点为： %s" % (i,j[0],j[1]))
                print("在主机 %s 上已经将盘 %s 拔出,原先的mount点为： %s" % (i,j[0],j[1]))

        except Exception as e:
            logging.error("get disk failed %s" % e)
            print(e)
            exit()

    return port_info


def plug_disk(port_info):

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())


    for i in port_info.keys():
        try:
            transport = paramiko.Transport(i, 22)
            transport.connect(username=dict['username'], password=dict['password'])
            ssh.connect(hostname=i, port=22, username=dict['username'], password=dict['password'])

            sftp = paramiko.SFTPClient.from_transport(transport)

            sftp.put('poweron_disk.sh', 'poweron_disk.sh')

            for j in port_info[i]:

                print("jjjj",j,port_info[i])
                stdin, stdout, stderr = ssh.exec_command(
                    'sudo /bin/bash  /home/hcd/poweron_disk.sh %s ' % j[0])
                stdout = stdout.read().decode()

                print(stdout)
                logging.warning("%s" %stdout)

                logging.warning("在主机 %s 上已经将盘 %s 插回去了" % (i,j[0]))
                print("在主机 %s 上已经将盘 %s 插回去了" % (i,j[0]))




        except Exception as e:
            logging.error("get disk failed %s" % e)
            print(e)
            exit()



def detect():
    headers = get_token()
    url='https://%s:8443/v1/clusters?clusterType=regular' %mvip
    r=requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    try:
        for i in json.loads(res.text)['data']:
            if i['state'] == "ONLINE":
                healthState = i['healthState']
                clusterAccessLevel = i['clusterAccessLevel']
                usedPercent = format(i['usedSpace'] / i['totalSpace']*100, '.2f')
                logging.warning("now cluster healthState is %s, clusterAccessLevel is  %s and storage usage is %s%%" %(healthState,clusterAccessLevel,usedPercent))
                print("now cluster healthState is %s, clusterAccessLevel is  %s and storage usage is %s%%" %(healthState,clusterAccessLevel,usedPercent))
                return healthState
    except Exception as e:
        logging.error("detect error %s" % e)



def judgeByservice():
    headers = get_token()

    url='https://%s:8443/v1/clusters?clusterType=regular' %mvip
    r = requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    try:
        for i in json.loads(res.text)['data']:
            if i['state']=='ONLINE':
                clusterId=i['clusterId']
    except Exception as e:
        logging.error("no online cluster find,please cheack")
        exit()

    url='https://%s:8443/v1/hosts?clusterId=%s&?filter=%%7B%%7D' %(mvip,clusterId)
    r = requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    host_Info = {}

    t2 = time.time()

    if t2 - t1 > 5400:
        logging.error("1.5h has been passed,but cluster still unhealthy")
        send_mail()

    try:
        for i in json.loads(res.text)['data']:
            if i['state'] != 'ONLINE':
                managementAddress = i['managementAddress']
                logging.error("%s archon service down, prepare send email" % managementAddress)
                send_mail()

    except Exception as e:
        logging.warning("host has no disks left" )





def detect_master(host):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(hostname=host, port=22, username=dict['username'],password=dict['password'])
        stdin, stdout, stderr = ssh.exec_command('/usr/sbin/ip addr|grep %s' % svip)

        stdout = stdout.read()
        time.sleep(2)
        if stdout:
            logging.warning("%s is hcdadmin Master host" %host)
        # else:
        #     logging.warning("%s is hcdadmin Backup host" %host)

        stdin, stdout, stderr = ssh.exec_command('/usr/sbin/ip addr|grep %s' % mvip)
        stdout = stdout.read()
        if stdout:
            logging.warning("%s is management Master host" %host)
        # else:
        #     logging.warning("%s is management Backup host" %host)
        internel_ip='192.168.206.%s' % host.split('.')[3]

        stdin, stdout, stderr = ssh.exec_command('sudo echo srvr | nc %s 2181 |grep leader' % internel_ip)
        stdout = stdout.read()
        if stdout:
            logging.warning("%s is zookeeper Master host" %host)
        # else:
        #     logging.warning("%s is zookeeper Backup host" %host)
        ssh.close()

    except Exception as e:
        logging.error("%s" % e)
        logging.error("plases cheack ssh info")
        ssh.close()
        exit()

def mutiple_detect():
    h = [dict['host0'], dict['host1'], dict['host2']]
    for i in h:
        t=threading.Thread(target=detect_master, args=(i,))
        t.start()

    t.join()

def send_mail():
    global number
    number= number + 1
    if number > 3:
        logging.error("has send 3 email, that is enough,abort script now")
        exit()
    username = "haiwangcao@hcdatainc.com"
    password = "Chw19910310"
    mail_from = "haiwangcao@hcdatainc.com"
    mail_to = "haiwangcao@hcdatainc.com,xiaoxueyao@hcdatainc.com"
    mail_subject = "cluster %s seem bug appear,please check" %mvip
    mail_body = "cluster %s seem bug appear,please check" %mvip

    mimemsg = MIMEMultipart()
    mimemsg['From'] = mail_from
    mimemsg['To'] = mail_to
    mimemsg['Subject'] = mail_subject
    mimemsg.attach(MIMEText(mail_body, 'plain'))
    try:
        connection = smtplib.SMTP(host='smtp.office365.com', port=587)
        connection.starttls()
        connection.login(username, password)
        connection.send_message(mimemsg)
        connection.quit()
    except Exception as e:
        logging.error("send email failed,please check email conf,%s" %e)


if __name__ == '__main__':
    number = 0
    args=config()

    cluster = args.cluster
    host = args.host
    times = args.times
    disk = args.disk
    dict = cluster_info(cluster)
    mvip = dict['mvip']
    svip = dict['svip']
    while 1:
        if detect() == 'HEALTHY':
            logging.warning("cluster is healthy now")
            break
        else:
            logging.warning("cluster is not healthy ,please check")
            time.sleep(120)
    logging.warning("will start disk failure")
    for i in range(88):
        mutiple_detect()
        choice_host = random.choice([dict['host0'], dict['host1'], dict['host2']])
        if host==1:
            logging.warning("will do disk failure test on %s" % choice_host)
            print("will do disk failure test on %s" % choice_host)
        else:
            tmp=[dict['host0'], dict['host1'], dict['host2']]
            tmp.remove(choice_host)
            logging.warning("will do disk failure test on 2 host : %s" % tmp)
            print("will do disk failure test on 2 host: %s" % tmp)

        host_Info = get_host()
        port_info = unplug_disk()
        t1 = time.time()
        time.sleep(times)
        plug_disk(port_info)
        while 1:
            if detect() == 'HEALTHY':
                logging.warning("cluster is healthy now")
                break
            else:
                judgeByservice()
                logging.warning("cluster is not healthy ,please check")
                time.sleep(120)











