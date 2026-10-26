apt-get update
apt-get upgrade
apt-get install -y bind9 bind9utils bind9-doc dnsutils

cp /vagrant/files/named /etc/default/named
cp /vagrant/files/named.conf.options.primario /etc/bind/named.conf.options
cp /vagrant/files/named.conf.local.primario /etc/bind/named.conf.local
cp /vagrant/files/alvaro.test.dns /var/lib/bind/alvaro.test.dns
cp /vagrant/files/alvaro.test.rev /var/lib/bind/alvaro.test.rev
chown root:bind /var/lib/bind/alvaro.test.dns /var/lib/bind/alvaro.test.rev
chmod 644 /var/lib/bind/alvaro.test.dns /var/lib/bind/alvaro.test.rev

systemctl restart named