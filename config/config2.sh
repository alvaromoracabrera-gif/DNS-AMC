apt-get update
apt-get upgrade
apt-get install -y bind9 bind9utils bind9-doc dnsutils

cp /vagrant/files/named /etc/default/named
cp /vagrant/files/named.conf.options.primario /etc/bind/named.conf.options
cp /vagrant/files/named.conf.local.primario /etc/bind/named.conf.local
cp /vagrant/files/richard.test.dns /var/lib/bind/richard.test.dns
cp /vagrant/files/richard.test.rev /var/lib/bind/richard.test.rev

systemctl restart named
/vagrant/test.sh
