#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if (apt-get update && apt-get install curl -y) ; then
    echo -e "curl installed successfully"
else
    echo -e "curl installiation is failed"
fi

if export INSTALL_K3S_EXEC="server --flannel-iface eth1 --node-ip 192.168.56.110 --bind-address 192.168.56.110 --advertise-address 192.168.56.110 --tls-san gbreanaS --write-kubeconfig-mode 644" ; then
    echo -e "INSTALL_K3S_EXEC exported successfully!"
else
    echo -e "INSTALL_K3S_EXEC not exported!"
fi

if (curl -sfL https://get.k3s.io | sh -) ; then
    echo -e "K3s master is installed!"
else
    echo -e "K3s installiation is failed!"
fi

# /vagrant is a shared dir between vm's
if cp /var/lib/rancher/k3s/server/token /vagrant/token.env ; then
    echo -e "Server\'s token is exported successful."
else
    echo -e "Export server\'s token is failed."
fi

echo "alias k='kubectl'" >> /etc/profile.d/aliases.sh

until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
    sleep 2
done
