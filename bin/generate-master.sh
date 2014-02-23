#!/bin/sh
#
# Copyright (C) 2014 JH de Wolff (jaap@de-wolff.org)
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

get_var() {
response=
while [ ! "$response" ]; do
echo -n $2
read -p ' > ' response
if [  "$response" ]; then
	eval $1=$response
else
	eval response=$1
fi
done
}


no_master_message() {
echo ==========================================================
echo ==    you have to be opengiethoorn master to run this   ==
echo ==========================================================
}


if [ ! "$(opkg list | grep openvpn-openssl)" ]; then
opkg update
opkg install openvpn-openssl 
fi


if [ ! "$(opkg list | grep openvpn-openssl)" ]; then
echo ==========================================================
echo ==    you have to install openvpn-openssl first!        ==
echo ==========================================================
exit 1
fi


if [ ! "$(opkg list | grep openvpn-easy-rsa)" ]; then
opkg update
opkg install openvpn-easy-rsa
fi

if [ ! "$(opkg list | grep openvpn-easy-rsa)" ]; then
echo ==========================================================
echo ==    you have to install openvpn-easy-rsa first!       ==
echo ==========================================================
exit 1
fi

if [ ! "$(opkg list | grep '^ip ')" ]; then
opkg update
opkg install ip
fi

if [ ! "$(opkg list | grep '^ip ')" ]; then
echo ==========================================================
echo ==           you have to install ip first!              ==
echo ==========================================================
exit 1
fi

touch /etc/config/opengiethoorn
if [ "$(uci show opengiethoorn)" ]; then
echo ==========================================================
echo ==    looks like opengiethoorn is already initialized   ==
echo ==    you have to remove it first before creating       ==
echo ==========================================================
exit 1
fi

# find the openvpn-easy-rsa key dir.
dummy=$(opkg files openvpn-easy-rsa | grep index.txt)
RSAKEY_DIR=${dummy%/*}


GIETHOORN_DIR="/usr/share/open-giethoorn"
GIETHOORN_CONF_DIR=/etc/open-giethoorn
GIETHOORN_DATA_DIR=$GIETHOORN_DIR/data
GIETHOORN_BIN_DIR=$GIETHOORN_DIR/bin
OPENVPN_DIR="/etc/openvpn"

mkdir -p $GIETHOORN_CONF_DIR
KEY_SIZE=1024



HOST=$(ifconfig `route | grep default | awk '{print $8}'` | grep "inet " | awk '{print $2}' | awk -F: '{print $2}')

get_var HOST "On what ip address you can be reached from the internet or \n"\
"(better) what is the hostname your router can be reached on the internet?\n"\
"[$HOST]"


$GIETHOORN_BIN_DIR/generate-key-info.sh

IMPORT="$GIETHOORN_CONF_DIR/key_data.txt"

for i in `cat ${IMPORT}`
do
VAR_COMMONNAME=`echo $i | awk -F, '{print $1}'`
KEY_COUNTRY=`echo $i | awk -F, '{print $2}'`
KEY_PROVINCE=`echo $i | awk -F, '{print $3}'`
KEY_CITY=`echo $i | awk -F, '{print $4}'`
KEY_ORG=`echo $i | awk -F, '{print $5}'`
KEY_OU=`echo $i | awk -F, '{print $6}'`
KEY_EMAIL=`echo $i | awk -F, '{print $7}'`
KEY_PASSWORD=""
KEY_CN=`echo "$VAR_COMMONNAME"-server`
done

RSA_VARS=$(opkg files openvpn-easy-rsa | grep vars)
mv $RSA_VARS ${RSA_VARS}.bak
cat ${RSA_VARS}.bak | sed \
-e s/"export KEY_SIZE=.*"/"export KEY_SIZE=$KEY_SIZE"/g \
-e s/"export KEY_COUNTRY=.*"/"export KEY_COUNTRY=\"$KEY_COUNTRY\""/g \
-e s/"export KEY_PROVINCE=.*/export KEY_PROVINCE=\"$KEY_PROVINCE\""/g \
-e s/"export KEY_CITY=.*"/"export KEY_CITY=\"$KEY_CITY\""/g \
-e s/"export KEY_ORG=.*"/"export KEY_ORG=\"$KEY_ORG\""/g \
-e s/"export KEY_EMAIL=.*"/"export KEY_EMAIL=\"$KEY_EMAIL\""/g \
-e s/"export KEY_OU=.*"/"export KEY_OU=\"$KEY_OU\""/g > $RSA_VARS

if  [ ! -f $RSAKEY_DIR/dh1024.pem ]; then
	clean-all
	openssl dhparam -out $RSAKEY_DIR/dh1024.pem 1024
fi

if  [ ! -f $RSAKEY_DIR/ca.key ]; then
pkitool --initca  > /dev/null
fi

mkdir $GIETHOORN_CONF_DIR/Common

cp $RSAKEY_DIR/* $GIETHOORN_CONF_DIR/Common/
cp $RSAKEY_DIR/dh1024.pem $OPENVPN_DIR/
cp $RSAKEY_DIR/*.key $OPENVPN_DIR/
cp $RSAKEY_DIR/*.crt $OPENVPN_DIR/

$GIETHOORN_CONF_DIR/generate-server.sh 15 $VAR_COMMONNAME $VAR_COMMONNAME $HOST
uci set opengiethoorn.count=0
uci commit opengiethoorn

uci set opengiethoorn.$VAR_COMMONNAME.host=$HOST
SHELLFILE=$GIETHOORN_CONF_DIR/client-info15.txt
echo $VAR_COMMONNAME,192.168.15.1,$HOST > $SHELLFILE





