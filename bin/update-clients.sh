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

# wait, to let all clients start
if [ $1 ]; then
sleep $1
fi

#update our client.txt
cat $GIETHOORN_CONF_DIR/client-info*.txt > $GIETHOORN_CONF_DIR/client.txt
cp $GIETHOORN_CONF_DIR/client.txt /www/og.txt
#update our clients
/etc/init.d/openvpn stop
$GIETHOORN_BIN_DIR/generate-clients.sh
# now all our configurations are updated, restart services and rules
/etc/init.d/openvpn start
/etc/init.d/dnsmasq restart
# wait some time for connections to come up
sleep 10
for i in `ls $GIETHOORN_BIN_DIR/create-route*.sh`
do
$i
done

