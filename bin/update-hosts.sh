#!/bin/sh
#
# Copyright (C) 2014 JH de Wolff 
#
# This file is a part of the open-giethoorn project 
#	http://github.com/de-wolff/OpenGiethoorn
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#


. /usr/share/open-giethoorn/bin/vars

VAR_COMMONNAME=`uci get opengiethoorn.server`
IMPORT="$GIETHOORN_CONF_DIR/client.txt"
while true
# wait 10 minutes
sleep 6000
do
#get our lease file
LEASES=$(uci show dhcp | grep dnsmasq.*leasefile |awk -F= '{ print $2 }')
cat $LEASES |awk '{ print $3" "$4 }' >/www/leases.txt
VAR_COUNT=0
for i in `cat ${IMPORT}`
do
VAR_CLIENT_IP=`echo $i | awk -F, '{print $2}'`
VAR_CLIENT_NAME=`echo $i | awk -F, '{print $1}'`
rm /tmp/hosts/$VAR_CLIENT_NAME
wget http://$VAR_CLIENT_IP/leases.txt -O /tmp/hosts/$VAR_CLIENT_NAME
done
/etc/init.d/dnsmasq reload
done
