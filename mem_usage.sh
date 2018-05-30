#!/bin/bash

threshold=80
threshold2=90

usage=$(($(($(free -m |awk 'NR==2 {print $3}') * 100)) / 16010))

if [ "$usage" -gt "$threshold" ]

then

storj=$(ps -eF --sort=-rss|grep json|head -n1|awk -F"[/.]" '{print $13}')

/usr/bin/docker restart $storj

     if [ "$usage" -gt "$threshold2" ]

     then

	 top3=$(ps -eF --sort=-rss|grep json|head -n3|awk -F"[/.]" '{print $13}')

	 /usr/bin/docker restart $top3

	 current=$(($(($(free -m |awk 'NR==2 {print $3}') * 100)) / 16010))

     echo -e "The memory usage has reached $usage\% restarting:\n $top3\n Current usage: $current\%" | mail -s "High Memory Usage Alert" ${EMAIL}


     fi
fi
