#!/bin/sh
#
# Copyright (C) 2014 JH de Wolff (jaap@de-wolff.org)
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

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

