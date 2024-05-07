#!/usr/bin/python2
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
from email.header import Header

t=time.strftime("%Y%m%d%H%M", time.localtime())
logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S',filename='%s_service_failure.log' %t)

# logging.basicConfig(level=logging.WARNING,format='%(asctime)s - %(filename)s[line:%(lineno)d] - %(levelname)s: %(message)s', datefmt = '%Y-%m-%d %H:%M:%S')
def config():
    parser = argparse.ArgumentParser(description='service failure in cluster')
    parser.add_argument('--cluster', type=int, required=True, help='which cluster ')
    parser.add_argument('--type', type=str, required=True, choices=['restart','ss','reboot','detecte','random'], help='restart:  restart service,'
                                                                                                             'ss:  stop 10 minutes then start,'
                                                                                                             'reboot:  shutdown host,'
                                                                                                             'detecte: just detecte cluster healthy,'
                                                                                                             'random: do some random test'

                                                                                                                       )
    parser.add_argument('--service', type=str, required=False, choices=['hcdmgmt','hcdadmin'],help='which service or reboot your host ')
    args = parser.parse_args()
    return args

def cluster_info(cluster_number):
    with open('clusterinfo.ini', 'r') as f:

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
                print( "no cluster info find, please modify clusterinfo.ini" )
                exit()
    return dict

def stop_service(service):
    ipp = random.choice([dict['host0'], dict['host1'], dict['host2']])
    logging.warning("host %s service %s will stop" % (ipp,service))
    print( "host %s service %s will stop" % (ipp, service) )

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    transport = paramiko.Transport(ipp, 22)


    try:
        ssh.connect(hostname=ipp, port=22, username=dict['username'], password=dict['password'])
        # transport.connect(username=dict['username'], password=dict['password'])
        # sftp = paramiko.SFTPClient.from_transport(transport)


        ssh.exec_command('sudo systemctl stop %s' %service)
        logging.warning("stop command excute finish")
        print( "stop command excute finish" )
        ssh.close()
        return ipp


    except Exception as e:
        logging.error("%s" %e)
        print( "%s" % e )
        exit("ssh fail,abord,please ensure your username and password")


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
    # data = parse.urlencode(data1)
    url = 'https://%s:8443/oauth/token' % mvip
    r = requests.session()
    res = r.post(url=url, data=data1, headers=headers, verify=False)
    if res.status_code == 200:
        d1 = json.loads( res.text )[ 'access_token' ]
    else:
        data = {"grant_type": "password",
                "username": "admin",
                "password": "Welc0me!01"
                }
        r = requests.session()
        res = r.post(url=url, data=data, headers=headers, verify=False)
        if res.status_code != 200:
            print( "password is wrong, abort" )
            logging.error("password is wrong, abort")
            exit()
        else:
            d1 = json.loads( res.text )[ 'access_token' ]


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
                   'authorization': 'Bearer  %s' % d1
                   }
    return headers


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
                usedPercent = format(float(i['usedSpace']) / float(i['totalSpace'])*100, '.2f')
                logging.warning("now cluster healthState is %s, clusterAccessLevel is  %s and storage usage is %s%%" %(healthState,clusterAccessLevel,usedPercent))
                print("now cluster healthState is %s, clusterAccessLevel is  %s and storage usage is %s%%" %(healthState,clusterAccessLevel,usedPercent))
                return healthState
    except Exception as e:
        logging.error("detect error %s" % e)
        print( "detect error %s" % e )


def judgeBytime():
    t2 = time.time()
    if t2-t1 >5400:
        logging.error("1.5h has been passed,but cluster still unhealthy")
        print( "1.5h has been passed,but cluster still unhealthy" )
        send_mail()

def judgeByhost(ipp):
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
        print( "no online cluster find,please cheack" )
        exit()

    url='https://%s:8443/v1/hosts?clusterId=%s&?filter=%%7B%%7D' %(mvip,clusterId)
    r = requests.session()
    res = r.get(url=url, headers=headers, verify=False)
    t2 = time.time()
    if t2-t1 >5400:
        logging.error("1.5h has been passed,but cluster still unhealthy")
        print( "1.5h has been passed,but cluster still unhealthy" )
        send_mail()

    try:
        for i in json.loads(res.text)['data']:
            managementAddress = i['managementAddress']
            state = i['state']
            physicalState = i['physicalState']
            if managementAddress != ipp and state != 'ONLINE':
                logging.error("another host down, prepare send email")
                print( "another host down, prepare send email" )
                send_mail()
    except Exception as e:
        logging.error("detect error %s" % e)
        pritn( "detect error %s" % e )

def start_service(ipp,service):

    logging.warning("host %s service %s will start" % (ipp,service))
    print( "host %s service %s will start" % (ipp, service) )

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    transport = paramiko.Transport(ipp, 22)

    try:
        ssh.connect(hostname=ipp, port=22, username=dict['username'], password=dict['password'])
        # transport.connect(username=dict['username'], password=dict['password'])
        # sftp = paramiko.SFTPClient.from_transport(transport)

        ssh.exec_command("sudo systemctl start %s" % service)
        logging.warning("start command excute finish")
        print( "start command excute finish" )
        ssh.close()


    except Exception as e:
        logging.error("%s" %e)
        print( "%s" % e )
        exit("ssh fail,abord,please ensure your username and password")



def restart_service(service):
    ipp = random.choice([dict['host0'], dict['host1'], dict['host2']])

    logging.warning("host %s service %s will restart" % (ipp,service))
    print( "host %s service %s will restart" % (ipp, service) )
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    transport = paramiko.Transport(ipp, 22)
    try:
        ssh.connect(hostname=ipp, port=22, username=dict['username'], password=dict['password'])
        # transport.connect(username=dict['username'], password=dict['password'])
        # sftp = paramiko.SFTPClient.from_transport(transport)
        ssh.exec_command('sudo systemctl restart %s' %service)
        logging.warning("restart command excute finish")
        print( "restart command excute finish" )
        ssh.close()

    except Exception as e:
        logging.error("%s" %e)
        print( "%s" % e )
        exit("ssh fail,abord,please ensure your username and password")
    return ipp

def reboot():
    ipp = random.choice([dict['host0'], dict['host1'], dict['host2']])

    if ipp =='172.16.202.26':
        logging.error("172.16.202.26 can not do reboot opration")
        print( "172.16.202.26 can not do reboot opration" )
        return ipp
    else:
        logging.warning("host %s will reboot" % ipp)
        print( "host %s will reboot" % ipp )
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        transport = paramiko.Transport(ipp, 22)

        try:
            ssh.connect(hostname=ipp, port=22, username=dict['username'], password=dict['password'])
            # transport.connect(username=dict['username'], password=dict['password'])
            # sftp = paramiko.SFTPClient.from_transport(transport)
            ssh.exec_command('sudo reboot now')
            logging.warning("reboot command excute finish")
            print("reboot command excute finish")
            ssh.close()
        except Exception as e:
            logging.error("%s" % e)
            print("%s" % e)
            exit("ssh fail,abord,please ensure your username and password")

        return ipp


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
            print( "%s is hcdadmin Master host" % host )
        # else:
        #     logging.warning("%s is hcdadmin Backup host" %host)

        stdin, stdout, stderr = ssh.exec_command('/usr/sbin/ip addr|grep %s' % mvip)


        stdout = stdout.read()

        if stdout:
            logging.warning("%s is management Master host" %host)
            print( "%s is management Master host" % host )
        # else:
        #     logging.warning("%s is management Backup host" %host)


        internel_ip='192.168.206.%s' % host.split('.')[3]

        stdin, stdout, stderr = ssh.exec_command('sudo echo srvr | nc %s 2181 |grep leader' % internel_ip)

        stdout = stdout.read()

        if stdout:
            logging.warning("%s is zookeeper Master host" %host)
            print( "%s is zookeeper Master host" % host )
        # else:
        #     logging.warning("%s is zookeeper Backup host" %host)
        ssh.close()

    except Exception as e:
        logging.error("%s" % e)
        logging.error("plases cheack ssh info")
        print("%s" % e)
        print("plases cheack ssh info")
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
        print("has send 3 email, that is enough,abort script now")
        exit()
    USERNAME = "haiwangcao@hcdatainc.com"
    PASSWORD = "Chw19910310"
    TOADDR = [ "haiwangcao@hcdatainc.com,xiaoxueyao@hcdatainc.com" ]
    msg = MIMEText( "cluster %s seem bug appear,please check" %mvip, 'plain', 'utf-8' )
    msg[ 'Subject' ] = Header( "cluster %s seem bug appear,please check" %mvip, 'utf-8' )
    msg[ 'From' ] = USERNAME
    msg[ 'To' ] = ",".join( TOADDR )
    mailserver = smtplib.SMTP('smtp.office365.com', 587)
    mailserver.ehlo()
    mailserver.starttls()
    mailserver.login(USERNAME, PASSWORD)
    
    try:
        mailserver.sendmail( USERNAME, TOADDR, msg.as_string() )
    except Exception as e:
        logging.error( "send email failed,please check email conf,%s" % e )
        print("send email failed,please check email conf,%s" % e)
    mailserver.quit()

def run_servicefailure():
    global t1


    if type == 'restart' and not service is None:

        while 1:
            if detect() == 'HEALTHY':
                logging.warning("cluster is healthy now")
                print("cluster is healthy now")
                break
            else:
                logging.warning("cluster is not healthy ,please check")
                print("cluster is not healthy ,please check")
                time.sleep(120)
        logging.warning("will start service failure==='retsart service'")
        print("will start service failure==='retsart service'")
        for i in range(888):
            mutiple_detect()
            ipp = restart_service(service)

            t1 = time.time()
            time.sleep(300)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print("cluster is not healthy ,please check")
                    time.sleep(120)

    elif type == 'ss' and not service is None:
        while 1:
            if detect() == 'HEALTHY':
                logging.warning("cluster is healthy now")
                print("cluster is healthy now")
                break
            else:
                logging.warning("cluster is not healthy ,please check")
                print("cluster is not healthy ,please check")
                time.sleep(120)
        logging.warning("will start service failure===stop then start service")
        print("will start service failure===stop then start service")
        for i in range(88):
            mutiple_detect()
            ipp = stop_service(service)
            time.sleep(3660)
            start_service(ipp, service)

            t1 = time.time()
            time.sleep(120)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
		    time.sleep(3600)
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print("cluster is not healthy ,please check")
                    time.sleep(120)
    elif type == 'reboot':
        while 1:
            if detect() == 'HEALTHY':
                logging.warning("cluster is healthy now")
                print("cluster is healthy now")
		time.sleep(3600)
                break
            else:
                logging.warning("cluster is not healthy ,please check")
                print("cluster is not healthy ,please check")
                time.sleep(120)
        logging.warning("will start host failure")
        print("will start host failure")
        for i in range(88):
            mutiple_detect()
            ipp = reboot()

            t1 = time.time()
            time.sleep(300)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
		    time.sleep(3600)
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print("cluster is not healthy ,please check")
                    time.sleep(120)

    elif type == 'detecte':
        if detect() == 'HEALTHY':
            logging.warning("cluster is healthy now")
            print("cluster is healthy now")
        else:
            logging.warning("cluster is not healthy ,please check")
            print("cluster is not healthy ,please check")
        mutiple_detect()

    else:
        logging.error("please special one service")
        print("please special one service")
        exit()

def run_random():
    global t1
    while 1:
        if detect() == 'HEALTHY':
            logging.warning("cluster is healthy now")
            print("cluster is healthy now")
            break
        else:
            logging.warning("cluster is not healthy ,please check")
            print("cluster is not healthy ,please check")
            time.sleep(120)
    for i in range(88):
        random_type = random.choice(['restart', 'ss', 'reboot'])
        print("will do %s failure" %random_type)
        logging.warning("will do %s failure" %random_type)
        print("will do %s failure" %random_type)
        if random_type == 'restart':
            random_service = random.choice(['hcdadmin', 'hcdmgmt'])

            logging.warning("will start %s service failure==='retsart service'" % random_service)
            print("will start %s service failure==='retsart service'" % random_service)
            mutiple_detect()
            ipp = restart_service(random_service)

            t1 = time.time()
            time.sleep(300)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print("cluster is not healthy ,please check")
                    time.sleep(120)


        elif random_type == 'ss':
            random_service = random.choice(['hcdadmin', 'hcdmgmt'])
            logging.warning("will begin %s service failure===stop then start" % random_service)
            print("will begin %s service failure===stop then start" % random_service)
            mutiple_detect()
            ipp = stop_service(random_service)
            time.sleep(4000)

            start_service(ipp, random_service)

            t1 = time.time()
            time.sleep(120)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print( "cluster is not healthy ,please check" )
                    time.sleep(120)

        elif random_type == 'reboot':
            logging.warning("will start host failure: reboot")
            print( "will start host failure: reboot" )
            mutiple_detect()
            ipp = reboot()

            t1 = time.time()
            time.sleep(300)
            while 1:
                if detect() == 'HEALTHY':
                    logging.warning("cluster is healthy now")
                    print("cluster is healthy now")
                    break
                else:
                    judgeBytime()
                    judgeByhost(ipp)
                    logging.warning("cluster is not healthy ,please check")
                    print("cluster is not healthy ,please check")
                    time.sleep(120)
        else:
            logging.error("something wrong ,abort")
            print( "something wrong ,abort" )
            exit()
        time.sleep(3600)





if __name__ == '__main__':
    number = 0
    args=config()
    cluster = args.cluster
    service = args.service
    dict = cluster_info(cluster)
    mvip = dict['mvip']
    svip = dict['svip']
    type = args.type
    if type == 'random':
        run_random()
    else:
        run_servicefailure()






