#!/bin/bash

# enable ip_forward
#echo 1 > /proc/sys/net/ipv4/ip_forward
#vi /etc/syscrl.conf

# Flush All Rules
/sbin/iptables -t nat -F PREROUTING
/sbin/iptables -t nat -F POSTROUTING

/sbin/iptables -t filter -F INPUT
/sbin/iptables -t filter -F FORWARD
/sbin/iptables -t filter -F OUTPUT

# Set Default POLICY DROP
/sbin/iptables -t filter -P INPUT DROP
/sbin/iptables -t filter -P OUTPUT DROP
/sbin/iptables -t filter -P FORWARD DROP

#SNAT
/sbin/iptables -t nat -A POSTROUNTING -s 10.10.10.0/24 -o eth0 -j SNAT --to-source 172.16.0.105
/sbin/iptables -t nat -A POSTROUNTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE

#DNAT

/sbin/iptables -t nat -A POSTROUNTING -s 10.10.10.0/24 -o eth0 -j SNAT --to-source 172.16.0.105
/sbin/iptables -t nat -A POSTROUNTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE

/sbin/iptables -t filter -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
/sbin/iptables -t filter -A INPUT -i eth0 -p tcp --dport 80 -j ACCEPT

echo "1" > /proc/sys/net/ipv4/ip_forward

























