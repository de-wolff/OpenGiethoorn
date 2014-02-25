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

GIETHOORN_DIR="/usr/share/open-giethoorn"
GIETHOORN_CONF_DIR="/etc/open-giethoorn"
GIETHOORN_BIN_DIR=$GIETHOORN_DIR/bin
GIETHOORN_DATA_DIR=$GIETHOORN_DIR/data
OPENVPN_DIR="/etc/openvpn"

OLD_DIR=`pwd`
cd $GIETHOORN_DATA_DIR
# find the openvpn-easy-rsa key dir.
dummy=$(opkg files openvpn-easy-rsa | grep index.txt)
RSAKEY_DIR=${dummy%/*}

for i in `ls -1 *.tgz`
do
tar -xzf $i
mv -f open.vpn/*.txt $GIETHOORN_CONF_DIR/
mv -f open.vpn/rsa/* $RSAKEY_DIR/
cp $RSAKEY_DIR/dh1024.pem $OPENVPN_DIR/
cp $RSAKEY_DIR/*.key $OPENVPN_DIR/
cp $RSAKEY_DIR/*.crt $OPENVPN_DIR/
rm -rf open.vpn
done

SERVER=$GIETHOORN_CONF_DIR/server.txt
MASTER=$GIETHOORN_CONF_DIR/master.txt

if  [ ! -f $SERVER ]; then
exit 1
fi

if  [ ! -f $MASTER ]; then
exit 1
fi

for i in `cat ${SERVER}`
do
VAR_SERVER_NAME=`echo $i | awk -F, '{print $1}'`
VAR_SERVER_IP=`echo $i | awk -F, '{print $2}'`
VAR_SERVER_HOST=`echo $i | awk -F, '{print $3}'`
done

for i in `cat ${MASTER}`
do
VAR_MASTER_NAME=`echo $i | awk -F, '{print $1}'`
VAR_MASTER_IP=`echo $i | awk -F, '{print $2}'`
VAR_MASTER_HOST=`echo $i | awk -F, '{print $3}'`
done

VAR_COUNT=`echo $VAR_SERVER_IP | awk -F. '{print $3 }' `

$GIETHOORN_BIN_DIR/generate-server.sh $VAR_COUNT $VAR_MASTER_NAME $VAR_SERVER_NAME $VAR_SERVER_HOST
$GIETHOORN_BIN_DIR/generate-client.sh 1 $VAR_MASTER_NAME $VAR_SERVER_NAME $VAR_MASTER_IP $VAR_MASTER_HOST

cd $OLD_DIR

