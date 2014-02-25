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

. vars

write_firewall_tap_forwarding() {
if [ ! "$(uci show firewall | grep forwarding.*dst=tap$1 )" ]; then
uci add firewall.forwarding
uci set firewall.@forwarding[-1].src=lan
uci set firewall.@forwarding[-1].dst=tap$1
fi
}

write_firewall_tap_zone() {
if [ ! "$(uci show firewall | grep zone.*name=tap$1 )" ]; then
uci add firewall.zone
uci set firewall.@zone[-1].name=tap$1
uci set firewall.@zone[-1].device=tap$1
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
fi
}


if [ ! "$1" ]; then
	echo this script should be called from another script
	exit 1
fi

if [ ! "$2" ]; then
	echo this script should be called from another script
	exit 1
fi

if [ ! "$3" ]; then
	echo this script should be called from another script
	exit 1
fi

if [ ! "$4" ]; then
	echo this script should be called from another script
	exit 1
fi

rt_tables=`opkg files ip | grep rt_tables`
if [ ! "$rt_tables" ]; then
	echo this script requires ip to be installed
	exit 1
fi

CLIENTTEMPLATE="$GIETHOORN_DATA_DIR/openvpn.client"

VAR_COUNT=$1
VAR_COMMONNAME=$2
VAR_SELF=$3
VAR_CLIENT_IP=$4
VAR_HOST=$5
VAR_CLIENT_IPPART=`echo $VAR_CLIENT_IP | awk -F. '{print $1 "." $2 "." $3 "." }' `

for l in `cat $CLIENTTEMPLATE | sed \
-e s/VAR_COMMONNAME/$VAR_COMMONNAME/g \
-e s/VAR_HOST/$VAR_HOST/g \
-e s/VAR_SELF/$VAR_SELF/g \
-e s/VAR_COUNT/$VAR_COUNT/g `
do
dummy=`echo $l | awk -F~ '{ print $1 $2 $3 $4 }'`
uci set openvpn.${VAR_COMMONNAME}$dummy
done

#disable entry if no host info is available
if [ ! "$VAR_HOST" ]; then
uci set openvpn.$VAR_COMMONNAME.enabled=0
fi
uci commit openvpn

#update firewall
write_firewall_tap_forwarding $VAR_COUNT
write_firewall_tap_zone $VAR_COUNT
uci commit firewall

# set opengiethoorn vars
uci set opengiethoorn.$VAR_COMMONNAME=opengiethoorn
uci set opengiethoorn.$VAR_COMMONNAME.client=$VAR_COMMONNAME
if [ "$VAR_HOST" ]; then
uci set opengiethoorn.$VAR_COMMONNAME.host=$VAR_HOST
fi
uci set opengiethoorn.$VAR_COMMONNAME.device=tap$VAR_COUNT
uci commit opengiethoorn

# add the ip route tables if neccesary
if [ ! "$( cat $rt_tables | grep vpn$VAR_COUNT )" ]; then
echo # create a table to route to $VAR_COMMONNAME in range $VAR_CLIENT_IPPART0/24 >> $rt_tables
echo 1$VAR_COUNT vpn$VAR_COUNT >> $rt_tables
fi

# add the nameserver of the remote domain:
for i in $( uci show dhcp | grep resolvfile= ) 
do
RESOLV_FILE=$( awk -F= '{ print $1 }' )
if [ ! "$( grep $VAR_COMMONNAME.local $RESOLV_FILE )" ]; then
echo # added by open-giethoorn >> $RESOLV_FILE
echo nameserver $VAR_CLIENT_IP >> $RESOLV_FILE
echo search $VAR_COMMONNAME.local >> $RESOLV_FILE
fi
done 

# create shellfile to create tap devices

SHELLFILE=$GIETHOORN_BIN_DIR/create-tap$VAR_COUNT.sh
echo "if [ ! -d /sys/devices/virtual/net/tap$VAR_COUNT ]; then" > $SHELLFILE
echo "openvpn --mktun --dev tap$VAR_COUNT" >> $SHELLFILE
echo "fi" >> $SHELLFILE
chmod 755 $SHELLFILE

SHELLFILE=$GIETHOORN_BIN_DIR/create-route$VAR_COUNT.sh
echo "test = \$(ip rule show| grep \"to ${VAR_CLIENT_IPPART}0/24 lookup vpn$VAR_COUNT\")" >$SHELLFILE
echo 'if [ ! "$test" ]; then' >> $SHELLFILE
echo "ip rule add to ${VAR_CLIENT_IPPART}0/24 lookup vpn$VAR_COUNT" >> $SHELLFILE
echo "fi" >> $SHELLFILE
echo "ip route flush table vpn$VAR_COUNT" >> $SHELLFILE
echo "ip route add table vpn$VAR_COUNT default via ${VAR_CLIENT_IPPART}1" >> $SHELLFILE
chmod 755 $SHELLFILE

