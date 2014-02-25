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

VAR_COMMONNAME=$1

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

if [ ! $VAR_COMMONNAME ]; then
	get_var VAR_COMMONNAME "Your unique name (No spaces or special characters allowed).\n"\
	"good choices is:\your full name in the form FirstnameLastname.", "([A-Za-z1-9!.\-][A-Za-z1-9!.\-]*)"
fi
get_var VAR_COUNTRY "In which country do you live (2 chars)?" "^[A-Za-z][A-Za-z]$"
get_var VAR_PROVINCE "In which state/provence do you live (2 chars)?" "^[A-Za-z][A-Za-z]$"
get_var VAR_CITY "In which city do you live?" "^[^ \t\n\r][^ \t\n\r]*$"
get_var VAR_ORG "What organisation do you represent?" "^[^ \t\n\r][^ \t\n\r]*$"
get_var VAR_OU "What organisational unit do you represent?" "^[^ \t\n\r][^ \t\n\r]*$"
get_var VAR_EMAIL "What is your email address?" "^[^ \t\n\r][^ \t\n\r]*@[^ \t\n\r][^ \t\n\r]*$"
echo $VAR_COMMONNAME,$VAR_COUNTRY,$VAR_PROVINCE,$VAR_CITY,$VAR_ORG,$VAR_OU,$VAR_EMAIL > $GIETHOORN_CONF_DIR/key_data.txt

