today=$(curl -s -G 'http://0.0.0.0:8086/query?pretty=true' --data-urlencode "db=collectd" --data-urlencode "q=SELECT sum(\"value\") FROM \"storj_value\" WHERE \"type\" = 'shared' AND \"type_instance\" =~ /.*/ AND time >= now() -24h GROUP BY time(20s) fill(null)" |tail -30|egrep '[0-9]{9}'|awk '{ byte =$1 /1024/1024/1024; print byte }' |tail -1)
yesterday=$(curl -s -G 'http://0.0.0.0:8086/query?pretty=true' --data-urlencode "db=collectd" --data-urlencode "q=SELECT sum(\"value\") FROM \"storj_value\" WHERE \"type\" = 'shared' AND \"type_instance\" =~ /.*/ AND time >= 1529665842991ms and time <= 1530302824423ms GROUP BY time(20s) fill(null)" |tail -30|egrep '[0-9]{9}'|awk '{ byte =$1 /1024/1024/1024; print byte }' |tail -1)
total=$(echo "$today - $yesterday" | bc)

echo Storj has increased by $total Gb >> /opt/appdata/hass/Z.cal
