#!/bin/bash

ip_list="/opt/ssh.ip"

foe=$(grep -Po "(?<=from ).*(?= port)" /var/log/auth.log|sort -u|grep -v -E "$(cat /opt/ssh.ip|tr -d '\n')")

if [ ! -z ${foe} ]
 then
  if [ ${#foe} > 15 ]
   then
    log=$(echo ${foe}|sed 's/ /|/g')
  fi
  echo -n "|${log}" >> /opt/ssh.ip
curl  --silent --output /dev/null -X POST -H "Authorization: Bearer ${HASS_TOKEN}" -H "Content-Type: application/json" -d '{"title": "ssh","message": "https://whatismyipaddress.com/ip/'$(echo $log)'"}'  http://localhost:8123/api/services/notify/hass
fi
