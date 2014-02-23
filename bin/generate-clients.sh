#!/bin/sh

. vars

VAR_COMMONNAME=`uci get opengiethoorn.server`
IMPORT="$GIETHOORN_CONF_DIR/client.txt"
VAR_COUNT=0
for i in `cat ${IMPORT}`
do
VAR_COUNT=$((VAR_COUNT + 1))
VAR_CLIENT_NAME=`echo $i | awk -F, '{print $1}'`
VAR_CLIENT_IP=`echo $i | awk -F, '{print $2}'`
VAR_CLIENT_HOST=`echo $i | awk -F, '{print $3}'`
if [ $VAR_COMMONNAME != $VAR_CLIENT_NAME ]; then
$GIETHOORN_BIN_DIR/generate-client.sh $VAR_COUNT $VAR_CLIENT_NAME $VAR_COMMONNAME $VAR_CLIENT_IP $VAR_CLIENT_HOST
fi
done

