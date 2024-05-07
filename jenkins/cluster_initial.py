#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# 获取网页请求

import requests
import json
import random
import string
import urllib3
from requests.auth import HTTPBasicAuth

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# get access token


def get_access_token(base_endpoint, client_id, client_secret, grant_type, username, password):
    access_token_endpoint = base_endpoint + '/oauth/token'
    session_ = requests.Session()
    adapter = requests.adapters.HTTPAdapter(pool_connections=10, pool_maxsize=10)
    session_.mount('https://', adapter)
    response = session_.post(access_token_endpoint,
                             verify=False,
                             auth=(client_id, client_secret),
                             data={'grant_type': grant_type, 'username': username,
                                   'password': password}
                             )

    if response.status_code == 200:
        json_response_dict = response.json()
        access_token = json_response_dict.get('access_token')
        hcd_content_type = "application/json"
        full_token = {'authorization': 'Bearer {}'.format(access_token),
                      'Content-Type': '{}'.format(hcd_content_type)
                      }
        return full_token
    else:
        raise Exception('Failed to get an access token!')


def req(method, url, data, header):
    try:
        requests.packages.urllib3.disable_warnings()
        response = requests.request(method, url, data=data, headers=header, verify=False, timeout=20)
        response.raise_for_status()
        response.encoding = "utf-8"
        return response.json()
    except Exception as result:
        return result


# generated numbers randomly


def random_str(num):
    random_string = ''.join(random.sample(string.ascii_letters + string.digits, num))
    return random_string


def get_cluster_id(base_endpoint, header):
    get_cluster_url = base_endpoint + '/v1/clusters'
    method = "GET"
    payload = ""
    cluster_json = req(method, get_cluster_url, payload, header)
    for cluster_info in list(cluster_json.values())[0]:
        cluster_id = cluster_info.get('clusterId')
        # print(cluster_id)
        return cluster_id


def create_vol(base_endpoint, cluster_id, vol_num, header):
    for i in range(0, vol_num):
        # n = random.randint(2,20)
        # volume_name = random_str(n)
        method = "POST"
        url = base_endpoint + "/v1/volumes/task/create"
        # print (url) 1073741824000
	"""
	100G: 107374182400
	200G: 214748364800
	500G: 536870912000
	1T:   1099511627776
	2T:   2199023255552
	8T:   8796093022208
	"""
        payload = "{\"volumeName\":\"rdm-"+str(i)+"\"," \
                  "\"clusterId\": \""+str(cluster_id)+"\"," \
                  "\"volumeSize\": 1099511627776,\"blockSize\":512}\n"
        # print (payload)
        print(req(method, url, payload, header))


def create_ini(base_endpoint, ini_num, header):
    for i in range(0, ini_num):
        n = random.randint(2, 20)
        ini_name = random_str(n)
        method = "POST"
        ini_create_url = base_endpoint + "/v1/initiators"
        payload = "{\"initiatorName\":\"150\"," \
                  "\"iqn\": \"iqn.1994-05.com.redhat:yxx\"}"
      
        # payload = "{\"initiatorName\":\"157\",\"iqn\": \"iqn.1993-08.org.debian:01:87fe27d8cbc\"}"
        # payload = "{\"initiatorName\":\""+str(ini_name)+"\",\"iqn\": \"iqn.2020-06.test:test"+str(ini_name)+"\"}"
        print(req(method, ini_create_url, payload, header))


def create_user(base_endpoint, user_num, header):
    for i in range(0, user_num):
        user_n = random.randint(2, 20)
        user_name = ''.join(random.sample('abcdefghijklmnopqrstuvwxyz', user_n))
        method = "POST"
        user_create_url = base_endpoint + '/v1/users'
        payload = "{\"email\":\"testuser@test.com\"," \
                  "\"name\":\"test"+str(user_name)+"\"," \
                  "\"password\": \"Yxx123456!\"," \
                  "\"roles\": [\"ADMIN\"]," \
                  "\"username\":\"test"+str(user_name)+"\"}\n"
        # print (payload)
        print(req(method, user_create_url, payload, header))


def create_chap_account(base_endpoint, chap_num, cluster_id, header):
    for i in range(0, chap_num):
        chap_n = random.randint(2, 20)
        chap_name = ''.join(random.sample('abcdefghijklmnopqrstuvwxyz', chap_n))
        method = "POST"
        chap_create_url = base_endpoint + '/v1/chap-accounts'
        payload = "{\"clusterId\": \""+str(cluster_id)+"\"," \
                                                       "\"password\": \"Yxx123456!\"," \
                                                       "\"username\":\"test"+str(chap_name)+"\"}\n"
        # print (payload)
        print(req(method, chap_create_url, payload, header))


if __name__ == '__main__':

    mgmt_server_ip = "172.16.100.200"
    mgmt_server_port = "8443"
    hcd_client_id = "hcd-client"
    hcd_client_secret = "hcd-secret"
    hcd_grant_type = "password"
    hcd_username = "admin"
    hcd_password = "Hello123"
    hcd_base_endpoint = 'https://{}:{}'.format(mgmt_server_ip, mgmt_server_port)
    hcd_full_token = get_access_token(hcd_base_endpoint,
                                      hcd_client_id,
                                      hcd_client_secret,
                                      hcd_grant_type,
                                      hcd_username,
                                      hcd_password)
    print(hcd_full_token)
    hcd_cluster_id = get_cluster_id(hcd_base_endpoint, hcd_full_token)
    # print(cluster_id)
    create_num = 20
    create_vol(hcd_base_endpoint, hcd_cluster_id, create_num, hcd_full_token)
    # create_ini(hcd_base_endpoint, create_num, hcd_full_token)
    # create_user(hcd_base_endpoint, create_num, hcd_full_token)
    # create_chap_account(hcd_base_endpoint, create_num, hcd_cluster_id, hcd_full_token)

