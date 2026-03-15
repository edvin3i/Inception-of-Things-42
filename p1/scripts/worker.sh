#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

if (apt-get update && apt-get install curl -y) ; then
    echo -e "curl installed successfully"
else
    echo -e "curl installiation is failed"
fi

if export   INSTALL_K3S_EXEC="agent --flannel-iface eth1 --node-ip 192.168.56.111" \
            K3S_TOKEN="$(cat /vagrant/token.env)" \
            K3S_URL=https://192.168.56.110:6443 ; then
    echo -e "INSTALL_K3S_EXEC exported successfully!"
else
    echo -e "INSTALL_K3S_EXEC not exported!"
fi

if (curl -sfL https://get.k3s.io | sh -) ; then
    echo -e "K3s agent is installed!"
else
    echo -e "K3s installiation is failed!"
fi
