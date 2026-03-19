#!/bin/bash

echo -e "=== Prune all previous runs ==="
pkill -f "port-forward.*argocd"
k3d cluster delete dusty-cluster
echo -e "== PRUNE COMPLETE ==="


if ! k3d --version &>/dev/null ; then
    echo "k3d is not installed!"
    exit 1
else
    k3d cluster create 'dusty-cluster' -p "8888:8888@loadbalancer"
fi

if ! kubectl version --client &>/dev/null ; then
    echo "kubectl is not installed!"
    exit 1
else
    kubectl create namespace argocd
    kubectl apply --namespace argocd --server-side --force-conflicts \
            -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

    echo -e "\n=== Initial ArgoCD password ===:"
    kubectl --namespace argocd get secret argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d \
            && echo -e "\n=== END ===:"

    kubectl port-forward svc/argocd-server --namespace argocd 8080:443&

    kubectl create namespace dev
    kubectl apply -f confs/argocd_app.yaml
fi
