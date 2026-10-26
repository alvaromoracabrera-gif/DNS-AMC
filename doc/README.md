# DNS PRACTICE
## Álvaro Mora Cabrera
### Creating Vagrantfile
For making this practice, we should first create a Vagrantfile with the command:
```
vagrant init -m debian/bookworm64
```
Then, we should put this into the vagrantfile:
```Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"


  config.vm.define "srv1" do |srv|

    srv.vm.network "public_network", bridge: "enp64s0"

    # Red interna
    srv.vm.network "private_network",
      ip: "192.168.57.10"


    srv.vm.provision "shell",
      path: "config/config.sh"
    
  end

  config.vm.define "srv2" do |srv|

    srv.vm.network "public_network", bridge: "enp64s0"

      # Red interna
    srv.vm.network "private_network",
      ip: "192.168.56.10"


    srv.vm.provision "shell",
      path: "config/config2.sh"
      
  end

end
```
This way, we can install the VM, maintain the packages updated and install DNS server at the same time

### Configuring the primary server:

We acceed our server with this command to our principal DNS server:
``` 
vagrant ssh srv1
```
Then we edit the file /etc/bind/name.conf.options as sudo:
```
sudo nano /etc/bind/named.conf.options
```
And we add this to the file:
```
acl confiables {
    127.0.0.1;
    192.168.56.0/24;
};

options {
    directory "/var/cache/bind";

    // forwarders {
    //   0.0.0.0;
    // };

    allow-transfer { none; };
    listen-on port 53 { 127.0.0.1; 192.168.56.10; };

    recursion yes;
    allow-recursion { confiables; };

    dnssec-validation auto;

    // listen-on-v6 { any; };
};
```
This is available also in [`files/named.conf.options.primario`]

Then, we make this 3 commands:

```
named-checkconf /etc/bind/named.conf.options
echo "Resultado: $?"
sudo systemctl status named --no-pager
```
It should give an output like this:
```
Resultado: 0
● named.service - BIND Domain Name Server
     Loaded: loaded (/lib/systemd/system/named.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-10-26 21:28:39 UTC; 24min ago
       Docs: man:named(8)
   Main PID: 2211 (named)
     Status: "running"
      Tasks: 8 (limit: 496)
     Memory: 23.6M
        CPU: 25ms
     CGroup: /system.slice/named.service
             └─2211 /usr/sbin/named -f -u bind -4

Oct 26 21:28:39 bookworm named[2211]: managed-keys-zone: loaded serial 2
Oct 26 21:28:39 bookworm named[2211]: zone 0.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: zone 127.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: zone localhost/IN: loaded serial 2
Oct 26 21:28:39 bookworm named[2211]: zone 255.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: all zones loaded
Oct 26 21:28:39 bookworm systemd[1]: Started named.service - BIND Domain Name Server.
Oct 26 21:28:39 bookworm named[2211]: running
Oct 26 21:28:39 bookworm named[2211]: managed-keys-zone: Initializing automatic trust anchor management for zone '.'; DNSKEY ID 20326 is now trusted, waiving the normal 30-day waiting period.
Oct 26 21:28:39 bookworm named[2211]: managed-keys-zone: Initializing automatic trust anchor management for zone '.'; DNSKEY ID 38696 is now trusted, waiving the normal 30-day waiting period.
```

After this, we have to configure the file "named.conf.local"
```
sudo nano /etc/bind/named.conf.local
```
We are going to put this code:
```
zone "alvaro.test" {
    type master;
    file "/var/lib/bind/alvaro.test.dns";
    allow-transfer { 192.168.56.11; };
};

zone "56.168.192.in-addr.arpa" {
    type master;
    file "/var/lib/bind/alvaro.test.rev";
    allow-transfer { 192.168.56.11; };
};
```
Later, we have to edit (`/var/lib/bind/alvaro.test.dns`) and we add this code:

```
;
; alvaro.test
;
$TTL 86400
@ IN SOA debian.alvaro.test. admin.alvaro.test. (
        2026102201 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Negative Cache TTL
;
@                       IN NS    debian.alvaro.test.
@                       IN NS    debian2.alvaro.test.
debian.alvaro.test.     IN A     192.168.57.10
debian2.alvaro.test.    IN A     192.168.57.11
web.alvaro.test.        IN CNAME debian.alvaro.test.
@                       IN TXT   "amc"
```
For configuring a DNS zone, we have to configure a reverse one, so we edit the file (`/var/lib/bind/alvaro.test.rev`) and we add this code:

```
;
; 56.168.192
;
$TTL 86400
@ IN SOA debian.alvaro.test. admin.alvaro.test. (
        2026102201 ; Serial
        3600       ; Refresh
        1800       ; Retry
        604800     ; Expire
        86400 )    ; Negative Cache TTL
;
@   IN NS  debian.alvaro.test.
@   IN NS  debian2.alvaro.test.
10  IN PTR debian.alvaro.test.
11  IN PTR debian2.alvaro.test.
```
Just after that, we copy and paste these three commands:

```
named-checkzone alvaro.test /var/lib/bind/alvaro.test.dns
named-checkzone 56.168.192.in-addr.arpa /var/lib/bind/alvaro.test.rev
sudo journalctl -u named --no-pager | grep "loaded serial"
```
These were my outputs:
```
vagrant@bookworm:~$ named-checkzone alvaro.test /var/lib/bind/alvaro.test.dns
/var/lib/bind/alvaro.test.dns:14: ignoring out-of-zone data (debian.alvaro.test)
/var/lib/bind/alvaro.test.dns:15: ignoring out-of-zone data (debian2.alvaro.test)
/var/lib/bind/alvaro.test.dns:16: ignoring out-of-zone data (web.alvaro.test)
zone alvaro.test/IN: loaded serial 2026102201
OK
vagrant@bookworm:~$ named-checkzone 56.168.192.in-addr.arpa /var/lib/bind/alvaro.test.rev
zone 56.168.192.in-addr.arpa/IN: loaded serial 2026102201
OK
vagrant@bookworm:~$ sudo journalctl -u named --no-pager | grep "loaded serial"
Oct 26 21:09:54 bookworm named[2089]: managed-keys-zone: loaded serial 0
Oct 26 21:09:54 bookworm named[2089]: zone 0.in-addr.arpa/IN: loaded serial 1
Oct 26 21:09:54 bookworm named[2089]: zone localhost/IN: loaded serial 2
Oct 26 21:09:54 bookworm named[2089]: zone 127.in-addr.arpa/IN: loaded serial 1
Oct 26 21:09:54 bookworm named[2089]: zone 255.in-addr.arpa/IN: loaded serial 1
Oct 26 21:09:55 bookworm named[2116]: managed-keys-zone: loaded serial 0
Oct 26 21:09:55 bookworm named[2116]: zone localhost/IN: loaded serial 2
Oct 26 21:09:55 bookworm named[2116]: zone 0.in-addr.arpa/IN: loaded serial 1
Oct 26 21:09:55 bookworm named[2116]: zone 127.in-addr.arpa/IN: loaded serial 1
Oct 26 21:09:55 bookworm named[2116]: zone 255.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: managed-keys-zone: loaded serial 2
Oct 26 21:28:39 bookworm named[2211]: zone 0.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: zone 127.in-addr.arpa/IN: loaded serial 1
Oct 26 21:28:39 bookworm named[2211]: zone localhost/IN: loaded serial 2
Oct 26 21:28:39 bookworm named[2211]: zone 255.in-addr.arpa/IN: loaded serial 1
```
### Secondary server

We have to configure first 

### Verification with DIG and NSLOOKUP

We type these two commands:
```
dig @192.168.57.11 debian.alvaro.test
nslookup debian.alvaro.test 192.168.57.11
```
The output must be this:
```
vagrant@bookworm:~$ dig @192.168.57.11 debian.alvaro.test

; <<>> DiG 9.18.49-1~deb12u2-Debian <<>> @192.168.57.11 debian.alvaro.test
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 44152
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 4e387721b3cfc9f2010000006adfe38c26900509f1ed6b93 (good)
;; QUESTION SECTION:
;debian.alvaro.test.		IN	A

;; ANSWER SECTION:
debian.alvaro.test.	86400	IN	A	192.168.57.10

;; Query time: 0 msec
;; SERVER: 192.168.57.11#53(192.168.57.11) (UDP)
;; WHEN: Mon Oct 26 23:34:36 UTC 2026
;; MSG SIZE  rcvd: 91

vagrant@bookworm:~$ nslookup debian.alvaro.test 192.168.57.11
Server:		192.168.57.11
Address:	192.168.57.11#53

Name:	debian.alvaro.test
Address: 192.168.57.10
```
