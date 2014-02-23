#!/bin/sh
. vars

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

dummy=$(opkg files openvpn-easy-rsa | grep index.txt)
RSAKEY_DIR=${dummy%/*}

KEY_SIZE=1024
IMPORT="$GIETHOORN_CONF_DIR/key_data.txt"

if  [ ! -f $IMPORT ]; then
$GIETHOORN_BIN_DIR/generate-key-info.sh $1
fi

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

if  [ ! -f $RSAKEY_DIR/$VAR_COMMONNAME-server.key ]; then
pkitool --server $VAR_COMMONNAME-server > /dev/null
fi
if  [ ! -f $RSAKEY_DIR/$VAR_COMMONNAME.key ]; then
export KEY_CN=$VAR_COMMONNAME
pkitool $VAR_COMMONNAME   > /dev/null
fi
cp $RSAKEY_DIR/$VAR_COMMONNAME-server.key $OPENVPN_DIR/
cp $RSAKEY_DIR/$VAR_COMMONNAME-server.crt $OPENVPN_DIR/
cp $RSAKEY_DIR/$VAR_COMMONNAME.key $OPENVPN_DIR/
cp $RSAKEY_DIR/$VAR_COMMONNAME.crt $OPENVPN_DIR/
done

