#!/bin/bash

threshold=80
threshold2=90

usage=$(($(($(free -m |awk 'NR==2 {print $3}') * 100)) / 16010))

if [ "$usage" -gt "$threshold" ]

then

storjtop3=$(ps -eF --sort=-rss|grep json|head -n3|awk -F"[/.]" '{print $13}')

storj=$(docker stats $storjtop3 --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k 2 -h | grep -v CPU | head -1 | awk '{print $1}')

/usr/bin/docker restart $storj

     echo -e "The memory usage has reached $usage\% restarting:\n $storj\n Current usage: $current\%" | mail -s "Memory Usage Alert" ${EMAIL}

     if [ "$usage" -gt "$threshold2" ]

     then

	 storjtop3=$(ps -eF --sort=-rss|grep json|head -n6|awk -F"[/.]" '{print $13}')
	 
	 storj=$(docker stats $storjtop3 --no-stream --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k 2 -h | grep -v CPU | head -3 | awk '{print $1}')

	 /usr/bin/docker restart storj

	 current=$(($(($(free -m |awk 'NR==2 {print $3}') * 100)) / 16010))

     echo -e "The memory usage has reached $usage\% restarting:\n $top3\n Current usage: $current\%" | mail -s "High Memory Usage Alert" ${EMAIL}


     fi
fi
