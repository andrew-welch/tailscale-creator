#!/bin/bash

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install wireguard qrencode git net-tools dialog cifs-utils

sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a  /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf

#IP4
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#IP6
sudo ip6tables -A FORWARD -i wg0 -j ACCEPT
sudo ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#NAT
sudo iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o eth0 -j MASQUERADE

#pretreat for iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

sudo apt-get -y install iptables-persistent
sudo systemctl enable netfilter-persistent
sudo netfilter-persistent save