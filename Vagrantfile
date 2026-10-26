Vagrant.configure("2") do |config|
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
      ip: "192.168.57.11"


    srv.vm.provision "shell",
      path: "config/config2.sh"
      
  end

end
