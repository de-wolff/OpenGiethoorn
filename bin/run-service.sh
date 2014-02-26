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

kill_processes() {
for proc in `jobs -p`
do
kill -9 $proc
done
exit
}

OPENVPN_DIR="/etc/openvpn"
PID_FILE=/var/run/opengiethoorn.pid
if [ -f /etc/config/opengiethoorn ]; then
if [ `uci show opengiethoorn| grep opengiethoorn.master` ]; then 
VAR_MASTERNAME=`uci get opengiethoorn.master`
fi
if [ `uci show opengiethoorn| grep opengiethoorn.server` ]; then 
VAR_COMMONNAME=`uci get opengiethoorn.server`
fi
fi

# start an update host file deamon
$GIETHOORN_BIN_DIR/update-hosts.sh &

CLIENTFILE=$GIETHOORN_CONF_DIR/client.txt
VAR_COUNT=0
DUMMY_FILE=$GIETHOORN_CONF_DIR/dummy.txt 

#stop openvpn
/etc/init.d/openvpn stop
#create all tunnels, necessary after each reboot
for i in `ls $GIETHOORN_BIN_DIR/create-tap*.sh`
do
$i
done
#start openvpn
/etc/init.d/openvpn start
# wait some time form connections to come up
sleep 10

#create rules to create route from lan to tapx
for i in `ls $GIETHOORN_BIN_DIR/create-route*.sh`
do
$i
done
VAR_COMMONNAME=`uci get opengiethoorn.server`
VAR_IP=`uci get opengiethoorn.$VAR_COMMONNAME.ipaddr`
VAR_COUNT=`echo $VAR_IP | awk -F. '{print $3 }' `
if [ `uci show opengiethoorn.$VAR_COMMONNAME | grep opengiethoorn.$VAR_COMMONNAME.host` ]; then
VAR_HOST=`uci get opengiethoorn.$VAR_COMMONNAME.host` 
else
VAR_HOST=$(ifconfig `route | grep default | awk '{print $8}'` | grep "inet " | awk '{print $2}' | awk -F: '{print $2}')
fi

#test if our address is correct
SERVERFILE=$GIETHOORN_CONF_DIR/client-info$VAR_COUNT.txt
echo $VAR_COMMONNAME,$VAR_IP,$VAR_HOST > $SERVERFILE
#now we are send our latest address to anyone, and get back their client address table
for i in  `ifconfig | grep tap | awk '{ print $1 }'` 
do
IPTEST=$(ifconfig $i | grep "inet " | awk '{ print $2 }' | awk -F: '{ print $2 }')
if [ "$IPTEST" ]; then
VAR_DEST=`echo $IPTEST| awk -F. '{print $1 "." $2 "." $3 ".1" }' `

echo $VAR_COMMONNAME,$VAR_IP,$VAR_HOST,$IPTEST > $DUMMY_FILE
nc -w 10 -c $VAR_DEST 6666 < $DUMMY_FILE
rm og.txt
wget http://$VAR_DEST/og.txt
if  [[ $? == 0 ]]; then
# update all known client entries
for j in  `cat og.txt`
do
VAR_CLIENT_NAME=`echo $j |awk -F, '{ print $1 }' `
VAR_CLIENT_IP=`echo $j |awk -F, '{ print $2 }' `
VAR_CLIENT_HOST=`echo $j |awk -F, '{ print $3 }' `
if [ $VAR_CLIENT_HOST ]; then
if [ $VAR_CLIENT_NAME != $VAR_COMMONNAME ]; then
VAR_CHANGED=TRUE
VAR_COUNT=`echo $VAR_CLIENT_IP | awk -F. '{print $3 }' `
echo $j > $GIETHOORN_CONF_DIR/client-info$VAR_COUNT.txt
fi
fi
done
fi
fi
done
if [ $VAR_CHANGED ]; then
#update our client.txt
$GIETHOORN_BIN_DIR/update-clients.sh &
fi

trap kill_processes 15

while true; do
for j in `nc -l -p 6666`
do
VAR_CLIENT_NAME=`echo $j |awk -F, '{ print $1 }' `
VAR_CLIENT_IP=`echo $j |awk -F, '{ print $2 }' `
VAR_CLIENT_HOST=`echo $j |awk -F, '{ print $3 }' `
if [ $VAR_CLIENT_HOST ]; then
if [ $VAR_CLIENT_NAME != $VAR_COMMONNAME ]; then
VAR_COUNT=`echo $VAR_CLIENT_IP | awk -F. '{print $3 }' `
uci set openvpn.$VAR_CLIENT_NAME.remote=$VAR_CLIENT_HOST
uci set openvpn.$VAR_CLIENT_NAME.enabled=1
VAR_CHANGED=TRUE
echo $j > $GIETHOORN_CONF_DIR/client-info$VAR_COUNT.txt
fi
fi
if [ $VAR_CHANGED ]; then
uci commit openvpn
#update our own client.txt
$GIETHOORN_BIN_DIR/update-clients.sh 240 &
fi
done
done
