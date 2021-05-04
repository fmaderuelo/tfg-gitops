Vagrant.configure("2") do |config|
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  config.vm.define "master-2" do |master|
    master.vm.box = "centos/7"
    master.vm.box_version = "2004.01"
    master.vm.hostname = "master-2.10.61.1.12.nip.io"
    master.vm.network "private_network", ip: "10.61.1.12"
    master.vm.provision "file", source: "./bastion/kubernetes.repo", destination: "/tmp/kubernetes.repo"
    master.vm.provision "shell", path: "./nodes/config.sh"
    master.vm.synced_folder '.', '/vagrant', disabled: true
    master.vm.provider "virtualbox" do |v|
      v.name = "master-2"
      v.memory = 4000
      v.cpus = 2
      v.customize [
        'modifyvm', :id,
        '--groups', '/TFG-GitOps/masters'
      ]
      ### Añadir disco sdb para Docker ###
      unless File.exists?("./volumes/master-2-docker/sdb.vdi")
        v.customize [
          'createmedium', 'disk',
          '--filename', "./volumes/master-2-docker/sdb.vdi",
          '--format', 'VDI',
          '--size', 20 * 1024
        ]
      end
      v.customize [
        'storageattach', :id,
        '--storagectl', 'IDE',
        '--port', 1,
        '--device', 0,
        '--type', 'hdd',
        '--medium', "./volumes/master-2-docker/sdb.vdi"
      ]
    end
  end


  (1..3).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.box = "centos/7"
      worker.vm.box_version = "2004.01"
      worker.vm.hostname = "worker-#{i}.10.61.1.2#{i}.nip.io"
      worker.vm.network "private_network", ip: "10.61.1.2#{i}"
      worker.vm.provision "file", source: "./bastion/kubernetes.repo", destination: "/tmp/kubernetes.repo"
      worker.vm.provision "shell", path: "./nodes/config.sh"
      worker.vm.synced_folder '.', '/vagrant', disabled: true
      worker.vm.provider "virtualbox" do |v|
        v.name = "worker-#{i}"
        v.memory = 3000
        v.cpus = 2
        v.customize [
          'modifyvm', :id,
          '--groups', '/TFG-GitOps/workers'
        ]
        ### Añadir disco sdb para Docker ###
        unless File.exists?("./volumes/worker-#{i}-docker/sdb.vdi")
          v.customize [
            'createmedium', 'disk',
            '--filename', "./volumes/worker-#{i}-docker/sdb.vdi",
            '--format', 'VDI',
            '--size', 20 * 1024
          ]
        end
        v.customize [
          'storageattach', :id,
          '--storagectl', 'IDE',
          '--port', 1,
          '--device', 0,
          '--type', 'hdd',
          '--medium', "./volumes/worker-#{i}-docker/sdb.vdi"
        ]
      end
    end
  end

  config.vm.define "master-1" do |bastion|
      bastion.vm.box = "centos/7"
      bastion.vm.box_version = "2004.01"
      bastion.vm.hostname = "master-1.10.61.1.11.nip.io"
      bastion.vm.network "private_network", ip: "10.61.1.11"
      bastion.vm.provision "file", source: "./bastion/password.txt", destination: "/tmp/password.txt"
      bastion.vm.provision "file", source: "./bastion/hostnames.txt", destination: "/tmp/hostnames.txt"
      bastion.vm.provision "file", source: "./bastion/kubernetes.repo", destination: "/tmp/kubernetes.repo"
      bastion.vm.provision "file", source: "./bastion/postinstall.sh", destination: "/tmp/postinstall.sh"
      bastion.vm.provision "file", source: "./extras/argocd-ingress.yaml", destination: "/tmp/argocd-ingress.yaml"
      bastion.vm.provision "file", source: "./extras/dashboard-ingress.yaml", destination: "/tmp/dashboard-ingress.yaml"
      bastion.vm.provision "file", source: "./extras/k8s-dashboard.yaml", destination: "/tmp/k8s-dashboard.yaml"
      bastion.vm.provision "file", source: "./extras/metallb-config.yaml", destination: "/tmp/metallb-config.yaml"
      bastion.vm.provision "file", source: "./extras/metallb-install.sh", destination: "/tmp/metallb-install.sh"
      bastion.vm.provision "file", source: "./extras/nginx-svc.yaml", destination: "/tmp/nginx-svc.yaml"
      bastion.vm.provision "file", source: "./ansible", destination: "/tmp/"
      bastion.vm.provision "shell", path: "./bastion/configbastion.sh"
      bastion.vm.synced_folder '.', '/vagrant', disabled: true
      bastion.vm.provider "virtualbox" do |v|
        v.name = "master-1"
        v.memory = 4000
        v.cpus = 2
        v.customize [
          'modifyvm', :id,
          '--groups', '/TFG-GitOps/masters'
        ]
        ### Añadir disco sdb para Docker ###
        unless File.exists?("./volumes/master-1-docker/sdb.vdi")
          v.customize [
            'createmedium', 'disk',
            '--filename', "./volumes/master-1-docker/sdb.vdi",
            '--format', 'VDI',
            '--size', 20 * 1024
          ]
        end
        v.customize [
          'storageattach', :id,
          '--storagectl', 'IDE',
          '--port', 1,
          '--device', 0,
          '--type', 'hdd',
          '--medium', "./volumes/master-1-docker/sdb.vdi"
        ]
      end
    end
end
