#!/usr/bin/python3
import socket
import requests
import os
from requests import get

fqdn = socket.getfqdn()
hostname = socket.gethostname()
domain = fqdn.split(".", 1)[1]
dns = "8.8.8.8"
# ip = socket.gethostbyname_ex(fqdn)
ip = os.popen("host " + fqdn + " " + dns).read().split(" ")[-1].strip()
url = "https://" + domain
new_ip = get(url).text.strip()
endpoint = "http://localhost:8123/api/services/notify/push"
data = '{{"title": "IP changed", "message": "Old: {0}\\nNew: {1}"}}'.format(ip, new_ip)
token = os.environ["HASS_TOKEN"]
headers = {"Authorization": "Bearer " + token}
username = os.environ["username"]
password = os.environ["password"]


def internet(host=dns, port=53, timeout=3):
    try:
        socket.setdefaulttimeout(timeout)
        socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect((host, port))
        return True
    except socket.error:
        return False


def update():
    params = (
        ("hostname", hostname),
        ("myip", new_ip),
    )
    response = requests.get(
        url + "/dyndns.php", params=params, auth=(username, password)
    )
    print(response.text.strip())


def notify():
    requests.post(endpoint, data=data, headers=headers).json()


if internet():
    if ip != new_ip:
        update()
        notify()
