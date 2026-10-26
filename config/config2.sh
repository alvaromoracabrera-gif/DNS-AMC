apt-get update
apt-get upgrade
apt-get install -y bind9 bind9utils dnsutils

cp /vagrant/files/named /etc/default/named
cp /vagrant/files/named.conf.options.secundario /etc/bind/named.conf.options
cp /vagrant/files/named.conf.local.secundario /etc/bind/named.conf.local

systemctl restart named