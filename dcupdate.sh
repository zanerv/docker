#!/bin/bash
ignored="storagenode|openvpn-monitor"
names=( $(/usr/bin/docker ps --format '{{.Names}}'|egrep -v ${ignored}) )

for i in ${names[*]}
  do
    lnames+=" ${i}"
done

/usr/bin/docker-compose --no-ansi -f /opt/docker-compose.yml pull ${lnames} >/dev/null 2>&1
/usr/bin/docker-compose --no-ansi -f /opt/docker-compose.yml up -d ${lnames} 2>&1|grep -Ev "\-date|orphan"
