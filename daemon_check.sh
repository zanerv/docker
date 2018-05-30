#!/bin/bash

for i in $(docker ps --format '{{.Names}}'|grep storj|tr -d storj)

     do

       if ! /usr/local/bin/storjshare-status -r 10.0.1.$i:45015 2> >(grep 'daemon is not running') > /dev/null 2>&1

       then

         /usr/bin/docker restart storj$i

         echo -e "Storj$i node restarted!" | mail -s "Storj$i Daemon Crash" ${EMAIL}

       fi
done
