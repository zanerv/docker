#!/bin/bash
# Display upcoming events in Nextcloud calendar
# Blog posts:
#   https://blog.sleeplessbeastie.eu/2018/06/11/how-to-display-upcoming-events-in-nextcloud-calendar-using-text-based-terminal-emulator/
#   https://blog.sleeplessbeastie.eu/2018/06/18/how-to-display-upcoming-events-in-nextcloud-calendar-using-shell-script/

# CalDav server and path
dav_server=${dav_server}
dav_path=${dav_path}

# Basic auth credentials
#username=${username}
#password=${password}
username=${1}
password=${2}
# Get URL for the user's principal resource on the server
dav_user_path=$(curl --silent \
                     --request PROPFIND \
                     --header 'Content-Type: text/xml' \
                     --header 'Depth: 0' \
                     --data '<d:propfind xmlns:d="DAV:">
                               <d:prop>
                                 <d:current-user-principal />
                               </d:prop>
                             </d:propfind>' \
                     --user ${username}:${password} \
                     ${dav_server}${dav_path} | \
                xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/d:current-user-principal/d:href' -n) 

# Get URL that contains calendar collections owned by the user
dav_user_calendar_home_path=$(curl --silent \
                              --request PROPFIND \
                              --header 'Content-Type: text/xml' \
                              --header 'Depth: 0' \
                              --data '<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                                        <d:prop>
                                          <c:calendar-home-set />
                                        </d:prop>
                                      </d:propfind>' \
                              --user ${username}:${password} \
                              ${dav_server}${dav_user_path} | \
                         xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/cal:calendar-home-set/d:href' -n) 

# Get calendar paths
dav_user_calendar_paths=$(curl --silent \
            	     --request PROPFIND \
                     --header 'Content-Type: text/xml' \
                     --header 'Depth: 1' \
                     --data '<d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/"><d:prop><d:displayname/></d:prop></d:propfind>' \
                     --user ${username}:${password} \
                     ${dav_server}${dav_user_calendar_home_path} | \
		     xmlstarlet sel -t -m 'd:multistatus/d:response' -i  "string-length(d:propstat/d:prop/d:displayname)" -i "d:propstat/d:status='HTTP/1.1 200 OK'" -v "d:href" -n)

# Define start/end date
date_start=$(date  +"%Y%m%dT000000" -d today)
date_end=$(date  +"%Y%m%dT000000" -d tomorrow)

# Get data for each calendar
for dav_user_calendar_path in ${dav_user_calendar_paths}; do
  # calendar name
  calendar_name=$(curl --silent \
                       --request PROPFIND \
                       --header "Content-Type: text/xml" \
                       --header 'Depth: 0' \
                       --user ${username}:${password} \
                       ${dav_server}${dav_user_calendar_path} | \
                       xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/d:displayname' -n)
  # event types stored in this calendar e.g. VTODO, VEVENTS
  component_types=$(curl --silent \
                         --request PROPFIND \
                         --header "Content-Type: text/xml" \
                         --header 'Depth: 0' \
                         --user ${username}:${password} \
                         ${dav_server}${dav_user_calendar_path} | \
                    xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/cal:supported-calendar-component-set/cal:comp/@name' -n)

  # initial values
  events=""
  events_count="0"
  todos=""
  todos_count="0"
  overdue_todos=""
  overdue_todos_count="0"
  general_todos=""
  general_todos_count="0"
  inotrfc_todos=""
  inotrfc_todos_count="0"

  case "${component_types}" in
    *VEVENT*)
      # Today's events
      events=$(curl --silent \
                    --request REPORT \
                    --header "Depth: 1" \
                    --header "Content-Type: text/xml" \
                    --data '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                              <d:prop><d:getetag /><c:calendar-data /></d:prop>
                              <c:filter>
                                <c:comp-filter name="VCALENDAR">
                                  <c:comp-filter name="VEVENT">
                                     <c:time-range  start="'${date_start}'" end="'${date_end}'"/>
                                  </c:comp-filter>
                                </c:comp-filter>
                              </c:filter>
                            </c:calendar-query>' \
                    --basic \
                    --user ${username}:${password} \
                    ${dav_server}${dav_user_calendar_path} | \
		    xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/cal:calendar-data' -n | \
               grep ^SUMMARY)
      events_count=$(echo "$events" | grep -c ^SUMMARY)
      ;&
    *VTODO*)
      # Tasks to be done today
      todos=$(curl --silent \
                    --request REPORT \
                    --header "Depth: 1" \
                    --header "Content-Type: text/xml" \
                    --data '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                              <d:prop><d:getetag /><c:calendar-data /></d:prop>
                              <c:filter>
                                <c:comp-filter name="VCALENDAR">
                                  <c:comp-filter name="VTODO">
                                     <c:prop-filter name="DUE">
                                       <c:time-range start="'${date_start}'" end="'${date_end}'"/>
                                       <c:is-defined/>
                                     </c:prop-filter>
                                     <c:prop-filter name="COMPLETED">
                                       <c:is-not-defined/>
                                     </c:prop-filter>
                                  </c:comp-filter>
                                </c:comp-filter>
                              </c:filter>
                            </c:calendar-query>' \
                    --user ${username}:${password} \
                    ${dav_server}${dav_user_calendar_path} | \
               xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/cal:calendar-data' -n | \

               grep ^SUMMARY)
      todos_count=$(echo "$todos" | grep -c ^SUMMARY)

      # Overdue tasks
      overdue_todos=$(curl --silent \
                    --request REPORT \
                    --header "Depth: 1" \
                    --header "Content-Type: text/xml" \
                    --data '<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
                              <d:prop><d:getetag /><c:calendar-data /></d:prop>
                              <c:filter>
                                <c:comp-filter name="VCALENDAR">
                                  <c:comp-filter name="VTODO">
                                     <c:prop-filter name="DUE">
                                     <c:time-range end="'${date_start}'"/>
                                       <c:is-defined/>
                                     </c:prop-filter>
                                     <c:prop-filter name="COMPLETED">
                                       <c:is-not-defined/>
                                     </c:prop-filter>
                                  </c:comp-filter>
                                </c:comp-filter>
                              </c:filter>
                            </c:calendar-query>' \
                    --user ${username}:${password} \
                    ${dav_server}${dav_user_calendar_path} | \
               xmlstarlet sel -t -v 'd:multistatus/d:response/d:propstat/d:prop/cal:calendar-data' -n | \
               grep ^SUMMARY)
      overdue_todos_count=$(echo "$overdue_todos" | grep -c ^SUMMARY)

      ;&
  esac

    if [ "$events_count" -lt "1" -a "$todos_count" -lt "1" ]; then
      echo "  There are no events, nor tasks for today"
    fi

    if [ "$events_count" -ge "1" ]; then
      echo "  Today's events: "
      printf "$events\n" | tr -s "\n" | sed "s/^SUMMARY://" | while read event; do
        echo "    - $event"
      done
    # else
      # echo "  There are no events for today"
    fi

    if [ "$todos_count" -ge "1" ]; then
      echo " Tasks to be done today"
      printf "$todos\n" | tr -s "\n" | sed "s/^SUMMARY://" | while read todo; do
        echo "    - $todo"
      done
    # else
      # echo " There are no tasks for today"
    fi

    if [ "$overdue_todos_count" -ge "1" ]; then
      echo " Overdue tasks"
      printf "$overdue_todos\n" | tr -s "\n" | sed "s/^SUMMARY://" | while read todo; do
        echo "    - $todo a"
      done
    fi


done
