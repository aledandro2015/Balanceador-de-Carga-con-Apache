Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian12"

  # Capa 3: Servidor de Base de Datos (Subred 192.168.57.0/24)
  config.vm.define "AlejandroDuqueBBDD" do |bbdd|
    bbdd.vm.hostname = "AlejandroDuqueBBDD"
    bbdd.vm.network "private_network", ip: "192.168.57.20"
    bbdd.vm.provision "shell", path: "scripts/bbdd.sh"
  end

  # Capa 2: Servidor Web 1 (Subred 192.168.56.0/24 y 192.168.57.0/24)
  config.vm.define "AlejandroDuqueWeb1" do |web1|
    web1.vm.hostname = "AlejandroDuqueWeb1"
    web1.vm.network "private_network", ip: "192.168.56.11"
    web1.vm.network "private_network", ip: "192.168.57.11"
    web1.vm.provision "shell", path: "scripts/web.sh"
  end

  # Capa 2: Servidor Web 2 (Subred 192.168.56.0/24 y 192.168.57.0/24)
  config.vm.define "AlejandroDuqueWeb2" do |web2|
    web2.vm.hostname = "AlejandroDuqueWeb2"
    web2.vm.network "private_network", ip: "192.168.56.12"
    web2.vm.network "private_network", ip: "192.168.57.12"
    web2.vm.provision "shell", path: "scripts/web.sh"
  end

  # Capa 1: Balanceador de Carga Apache 2 (Subred 192.168.56.0/24 + Puertos Host)
  config.vm.define "AlejandroDuqueBalanceador" do |bal|
    bal.vm.hostname = "AlejandroDuqueBalanceador"
    bal.vm.network "private_network", ip: "192.168.56.10"
    bal.vm.network "forwarded_port", guest: 80, host: 8080
    bal.vm.network "forwarded_port", guest: 443, host: 8443

    bal.vm.provision "shell", path: "scripts/balanceador.sh"
    bal.vm.provision "letsencrypt", type: "shell", path: "scripts/ssl.sh",
      env: { "DUCKDNS_TOKEN" => ENV.fetch("DUCKDNS_TOKEN", "") }, run: "never"
  end

  config.vm.provider "vmware_desktop" do |v|
    v.gui = false
    v.memory = "1024"
    v.linked_clone = false
  end
end