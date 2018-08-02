#!/bin/bash
# Base URL.
site_url="https://www.storjdash.com"

# Endpoint URL for login action.
login_url="$site_url/login/"

# Path to cookie data.
cookie_path=/opt/appdata/hass/storjdash.com

get_data(){
# Get data from $site_url
total=$(curl -s --cookie $cookie_path https://www.storjdash.com/|grep "flipInX"|tail -1|grep -Po "(?<=>).*(?=<)")
}

login(){
# Authentication. POST to $login_url.
curl -s $login_url -c $cookie_path -d "email=$DASHBOARD_USER_EMAIL&password=$DASHBOARD_USER_SECRET" >> /dev/null

#curl -c $cookie_path -d "username=$DASHBOARD_USER_EMAIL&password=$DASHBOARD_USER_SECRET" "$login_url" -s >> /dev/null
}

get_data
if [[ -z $total ]] ; then
  login
  get_data
else

if [[ $total =~ "-" ]] ; then
  verb="decreased"
elif [[ $total != "-" ]] ; then
  verb="increased"
fi

fi

if [[ -z $verb ]] ; then
exit 1
fi

echo " " >> /opt/appdata/hass/Z.cal
echo "Storj has $verb by $total " >> /opt/appdata/hass/Z.cal
