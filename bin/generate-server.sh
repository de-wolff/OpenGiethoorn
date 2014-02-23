#!/bin/sh

. vars

write_firewall_openvpn_rule() {
if [ ! "$(uci show firewall | grep rule.*name=openvpn)" ]; then
uci add firewall.rule
uci set firewall.@rule[-1].name=openvpn
uci set firewall.@rule[-1].target=ACCEPT
uci set firewall.@rule[-1].dest_port=1194
uci set firewall.@rule[-1].src=wan
uci set firewall.@rule[-1].proto=tcpudp
uci set firewall.@rule[-1].family=ipv4
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

IP_ADDRESS=192.168.$1.1

SERVERTEMPLATE="$GIETHOORN_DATA_DIR/openvpn.server"

VAR_COMMONNAME=$3
$GIETHOORN_BIN_DIR/generate-keys.sh $VAR_COMMONNAME

VAR_MASTERNAME=$2
VAR_HOST=$4

VAR_COUNT=0
VAR_INT_IPADDR=$IP_ADDRESS
VAR_IPPART=`echo $IP_ADDRESS | awk -F. '{print $1 "." $2 "." $3 "." }' `
VAR_SELF=$VAR_COMMONNAME
for l in `cat $SERVERTEMPLATE | sed \
-e s/VAR_COMMONNAME/$VAR_COMMONNAME/g \
-e s/VAR_INT_IPADDR/$VAR_INT_IPADDR/g \
-e s/VAR_COUNT/$VAR_COUNT/g \
-e s/VAR_IPPART/$VAR_IPPART/g `
do
dummy=`echo $l | awk -F~ '{ print $1 $2 $3 $4 }'`
uci set openvpn.${VAR_COMMONNAME}$dummy
done
SERVER_BRIDGE="$VAR_INT_IPADDR 255.255.255.0 ${VAR_IPPART}80 ${VAR_IPPART}99"
uci set openvpn.${VAR_COMMONNAME}.server_bridge="$SERVER_BRIDGE"
uci set openvpn.${VAR_COMMONNAME}.keepalive="10 120"

uci commit openvpn

# set new ipaddress
uci set network.lan.ipaddr=$IP_ADDRESS
lan_ifname=`uci get network.lan.ifname`
if [ ! "$(echo $lan_ifname | grep tap0)" ]; then
uci set network.lan.ifname="$lan_ifname tap0"
fi
uci commit network

#test for dhcp dns options
if [ ! "$(uci show dhcp.lan.dhcp_option | grep =6)" ]; then
uci add_list dhcp.lan.dhcp_option=6,$IP_ADDRESS
fi

# open firewall for openvpn traffic

write_firewall_openvpn_rule

uci commit firewall

touch /etc/config/opengiethoorn
# set opengiethoorn vars
uci set opengiethoorn.master=$VAR_MASTERNAME
uci set opengiethoorn.server=$VAR_COMMONNAME
uci set opengiethoorn.$VAR_COMMONNAME=opengiethoorn
uci set opengiethoorn.$VAR_COMMONNAME.ipaddr=$IP_ADDRESS
uci set opengiethoorn.$VAR_COMMONNAME.host=$VAR_HOST
uci set opengiethoorn.$VAR_COMMONNAME.device=tap0
uci commit opengiethoorn

# create shellfile for creating tap devices

SHELLFILE=$GIETHOORN_BIN_DIR/create-tap0.sh
echo "if [ ! -d /sys/devices/virtual/net/tap0 ]; then" > $SHELLFILE
echo "openvpn --mktun --dev tap0" >> $SHELLFILE
echo "fi" >> $SHELLFILE
chmod 755 $SHELLFILE


