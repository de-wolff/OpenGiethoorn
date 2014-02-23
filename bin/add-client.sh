#!/bin/sh
#
# Copyright (C) 2014 JH de Wolff (jaap@de-wolff.org)
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

. vars


no_master_message() {
echo ==========================================================
echo ==    you have to be opengiethoorn master to run this   ==
echo ==========================================================
}

if  [ ! -f /etc/config/opengiethoorn ]; then
no_master_message
exit 1
fi

if [ ! "$(uci show opengiethoorn| grep opengiethoorn.master)" ]; then 
no_master_message
exit 1
fi

if [ ! "$(uci show opengiethoorn| grep opengiethoorn.server)" ]; then 
no_master_message
exit 1
fi

if [ ! "$(uci show opengiethoorn| grep opengiethoorn.count)" ]; then 
no_master_message
exit 1
fi

if [ $VAR_COMMONNAME != $VAR_MASTERNAME ]; then
no_master_message
exit 1
fi

get_var() {
response=
while [ !  "$response"  ]; do
echo -n $2
read -p ' > ' response
if [ -n "$response" ]; then
	eval $1=$response
fi
done
}

if [ ! $VAR_CLIENTNAME ]; then
	get_var VAR_CLIENTNAME "An unique name for the new network client (No spaces or special characters allowed)", "([A-Za-z1-9!.\-][A-Za-z1-9!.\-]*)"
fi

VAR_COUNT=`uci get opengiethoorn.count`
VAR_COUNT=$((VAR_COUNT + 1))
VAR_CLIENT_IP=192.168.$((15 - VAR_COUNT)).1
uci set opengiethoorn.count=$VAR_COUNT
uci set opengiethoorn.$VAR_CLIENTNAME=opengiethoorn
uci set opengiethoorn.$VAR_CLIENTNAME.ipaddr=$VAR_CLIENT_IP
uci commit opengiethoorn
$GIETHOORN_BIN_DIR/generate-client.sh $VAR_COUNT $VAR_CLIENTNAME $VAR_COMMONNAME $VAR_CLIENT_IP

SHELLFILE=$GIETHOORN_DATADIR/client-info$((15 - VAR_COUNT)).txt
echo $VAR_CLIENTNAME,$VAR_CLIENT_IP,$HOST > $SHELLFILE

IMPORT="$GIETHOORN_CONF_DIR/key_data.txt"

for i in `cat ${IMPORT}`
do
KEY_COUNTRY=`echo $i | awk -F, '{print $2}'`
KEY_PROVINCE=`echo $i | awk -F, '{print $3}'`
KEY_CITY=`echo $i | awk -F, '{print $4}'`
KEY_ORG=`echo $i | awk -F, '{print $5}'`
KEY_OU=`echo $i | awk -F, '{print $6}'`
KEY_EMAIL=`echo $i | awk -F, '{print $7}'`
KEY_PASSWORD=""
KEY_CN=`echo "$VAR_COMMONNAME"-server`
done


mkdir -p $GIETHOORN_CONF_DIR/open.vpn
mkdir $GIETHOORN_CONF_DIR/open.vpn/rsa
echo $VAR_CLIENTNAME,$VAR_COUNTRY,$VAR_PROVINCE,$VAR_CITY,$VAR_ORG,$VAR_OU,$VAR_EMAIL > $GIETHOORN_CONF_DIR/open.vpn/key_data.txt

cp $GIETHOORN_CONF_DIR/Common/* $GIETHOORN_CONF_DIR/open.vpn/rsa/
cp $SHELLFILE $GIETHOORN_CONF_DIR/open.vpn/server.txt
cp $GIETHOORN_CONF_DIR/client-info15.txt $GIETHOORN_CONF_DIR/open.vpn/
cp $GIETHOORN_CONF_DIR/client-info15.txt $GIETHOORN_CONF_DIR/open.vpn/client.txt
cp $GIETHOORN_CONF_DIR/client-info15.txt $GIETHOORN_CONF_DIR/open.vpn/master.txt
tar -czf $VAR_CLIENTNAME.tgz open.vpn/
rm open.vpn/rsa/*
rmdir open.vpn/rsa
rm open.vpn/*
rmdir open.vpn






