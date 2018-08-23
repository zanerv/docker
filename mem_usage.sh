#!/bin/bash

threshold1=80
threshold2=90

usage() {

usage=$(($(($(free -m |awk 'NR==2 {print $3}') * 100)) / 16010))

echo ${usage}

}

restart() {

/usr/bin/docker restart ${1}

echo "$(date) Memory above ${2}% restarting: ${1} Current usage: $(usage)%" >> /opt/mem.log

if [ $(cat /opt/mem.log|wc -l) -gt 5 ]; then

curl --silent --output /dev/null -X POST -H "Content-Type: application/json" -d '{"title": "Storj","message": "'"$(cat /opt/mem.log)"'"}'  http://localhost:8123/api/services/notify/hass

mv /opt/mem.log /opt/mem.log$(date +%d-%m);touch /opt/mem.log

fi

#curl --silent --output /dev/null -X POST -H "Content-Type: application/json" -d '{"title": "Storj","message": "Memory usage is above '${2}'% restarting:\n'${1}'\nCurrent usage: '$(usage)'%"}'  http://localhost:8123/api/services/notify/hass
#echo -e "The memory usage is above ${2}% restarting:\n ${1}\n Current usage: $(usage)%" | mail -s "OOM restarted ${1}" ${EMAIL}

}

storjtop() {

storj=$(docker stats $(ps -eF --sort=-rss|grep json|head -n${1}|awk -F"[/.]" '{print $13}') --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k 2 -h | grep -v CPU | head -${2} | awk '{print $1}'|tr '\r\n' ' ') >/dev/null 2>&1

echo ${storj}

}


if [ $(usage) -gt "${threshold1}" -a $(usage) -lt "${threshold2}" ]; then

restart "$(storjtop 3 1)" ${threshold1}

fi

if [ $(usage) -gt "${threshold2}" ]; then

restart "$(storjtop 6 3)" ${threshold2}

fi
