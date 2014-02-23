OpenGiethoorn
=============

a way to connect openwrt routers together over the internet, to form a larger network


It was started as a contest for http://tweakers.net, a dutch community for computer related issues.
The contest was about defining a new application for OpenWrt.

Giethoorn is a little town in the Netherlands, with a lot of water, and a lot of bridges.
(I think the number of bridges is bigger then the number of roads)

OpenGiethoorn should become a transparant bridge between different home networks, but at the 
moment it still behaves as a routed network.
It is possible to reach all connected devices in the greater network by means of IPV4, based on 
ip address, and more is to come.
To do this, I did not write any code, I am only using, what is already written for OpenWrt:

dnsmasq
firewall
ip (former ip-route2)
netcat
openvpn-openssl
openssl-util
openvpn-easy-rsa
uci
uhttpd

and in the future it will also use:

ebtables

The entire project is using shell scripts do glue those parts together. 



