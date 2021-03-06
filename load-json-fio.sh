#!/bin/bash

# This script is meant to streamline the process of getting files into Splunk.
# The goal is to:
# 1. Delete the specified INDEX and recreate it
# 2. Reload the input, fields, transforms, and props configs
# 3. oneshot load all of the files in specified directory using the defined sourcetype and INDEX
# 4. Count the number of events and show the field summary

SPLUNK_HOST=localhost:8089
#SPLUNK_HOST=localhost:8091
SPLUNK_USERNAME=admin
SPLUNK_PASS=welcome1
INDEX=unarchive_json_fio
SOURCETYPE=unarchive_json_fio
#DIRECTORY=.
DIRECTORY=./Docker/data/fio/
# Either set EXTENSION to something like json to load a number of files or set FILE_NAME to a 
# specific file name to load a single file. Don't set both. Leave the unused variable empty.
EXTENSION=
FILE_NAME=fio-1.json
APP_NAME=unarchive_test1
DEBUG=F # T or F

# URL escape codes used to pass special characters. DO NOT CHANGE!
dqt="%22"
pct="%25"

function splunk_search {
  #echo ${1}
  curl -s -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    https://${SPLUNK_HOST}/services/search/jobs/ \
    -d search="${1}" \
    -d exec_mode=oneshot -d count=100 -d output_mode=csv
}

function config_reload {
  local CONFIG="${1}"
  curl --write-out "${CONFIG} http-status: %{http_code}\n" --silent --output /dev/null \
    -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
    -X POST https://${SPLUNK_HOST}/services/configs/${CONFIG}/_reload
}
printf "\n\n"
# delete the index
curl --write-out "delete index http-status: %{http_code}\n" --silent --output /dev/null \
  -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
  -X DELETE https://${SPLUNK_HOST}/servicesNS/nobody/${APP_NAME}/data/indexes/${INDEX}
# create the index
curl --write-out "create index http-status: %{http_code}\n" --silent --output /dev/null \
  -k -u ${SPLUNK_USERNAME}:${SPLUNK_PASS}  \
  https://${SPLUNK_HOST}/servicesNS/nobody/${APP_NAME}/data/indexes  \
    -d name=${INDEX} \
    -d datatype=event

printf "\n"
config_reload "conf-inputs"
config_reload "conf-fields"
config_reload "conf-transforms"
config_reload "conf-props"
printf "\n"

for i in `ls -1 ${DIRECTORY}`
do
  if ([ -z "$FILE_NAME" ] && [ "${i}" != "${i%.${EXTENSION}}" ] || [ "${i}" == "${FILE_NAME}" ]);then
    echo $i
    splunk add oneshot -source ${DIRECTORY}/$i -index ${INDEX} -sourcetype ${SOURCETYPE} -auth "${SPLUNK_USERNAME}:${SPLUNK_PASS}";
    if [ "${DEBUG}" == "T" ];then
      echo "DEBUG waiting a few seconds so errors will be logged"
      sleep 3
      printf "\n\nErrors:\n"
      splunk_search "search index=_* OR index=* log_level=ERROR sourcetype=splunkd earliest=-1m 
        | where LIKE(data_source,${dqt}${pct}${i}${dqt}) 
        | eval time=strftime(_time, ${dqt}${pct}I:${pct}M:${pct}S:${pct}p${dqt})
        | table time,event_message" | sed 's/\"//g'| sed 's/,/ ,/g' | column -c 2 -t -s,
    fi
  fi
done

echo "Waiting a few seconds so some of the files will be indexed..."
sleep 3






printf "\n\nEvent Count:"
splunk_search "search index=${INDEX} | stats count"
printf "\n\nField Summary:\n"
splunk_search "search index=${INDEX} | fieldsummary | fields field,count" \
  | sed 's/,/ ,/g' | column -t -s,
printf "\n\nEvents:\n"
splunk_search "search index=${INDEX} | fields - _raw,index,timestamp,eventtype,punct,splunk_server,splunk_server_group,_bkt,_cd,tag,_sourcetype,_si,_indextime,source,host,_eventtype_color,linecount,${dqt}tag::eventtype${dqt} | table *" \
  | sed 's/,/ ,/g' | column -t -s,
printf "\n\n"
