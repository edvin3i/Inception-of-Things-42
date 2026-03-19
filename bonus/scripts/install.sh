#!/bin/bash

# Check the rights

if [ "$EUID" -ne 0 ]; then
    echo "Run as root: sudo $0"
    exit 1
fi

# apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

#----------------------------------------------#
#                                              #
# Docker installation from oficial repo       #
#                                              #
#----------------------------------------------#

if ! command -v docker &>/dev/null ; then
# Add Docker's official GPG key:
    apt update
    apt install ca-certificates curl -y
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
    tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
# Just update sources list and install
    apt update
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

else
    echo "Docker installed already!"
    docker --version
fi

# Add current user to docker group

if ! id -nG ${SUDO_USER:-$USER} | grep -qw docker ; then
    usermod -aG docker ${SUDO_USER:-$USER}
    echo "Log out and log back in, or run 'newgrp docker' for group to take effect"
fi

#----------------------------------------------#
#                                              #
# kubectl installation                         #
#                                              #
#----------------------------------------------#

# Download and install the kubectl
if ! kubectl version --client &>/dev/null ; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

else
    echo "kubectl installed already!"
    kubectl version --client
fi


#----------------------------------------------#
#                                              #
# k3d installation                             #
#                                              #
#----------------------------------------------#

# Just use the oficial script
if ! k3d --version &>/dev/null ; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

else
    echo "k3d installed already!"
    k3d --version
fi

#----------------------------------------------#
#                                              #
# Helm installation                            #
#                                              #
#----------------------------------------------#

# Download and install the Helm
if ! helm version --client &>/dev/null ; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash

else
    echo "Helm installed already!"
    helm version
fi
