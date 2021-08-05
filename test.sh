#!/bin/bash

DIRECTORY=./Docker/data/
EXTENSION=
FILE_NAME=foo.json

for i in `ls -1 ${DIRECTORY}`
do
  if ([ -z "$FILE_NAME" ] && [ "${i}" != "${i%.${EXTENSION}}" ] || [ "${i}" == "${FILE_NAME}" ]);then
    echo $i
    #splunk add oneshot -source ${DIRECTORY}/$i -index ${INDEX} -sourcetype ${SOURCETYPE} -auth "${SPLUNK_USERNAME}:${SPLUNK_PASS}";
  fi
done