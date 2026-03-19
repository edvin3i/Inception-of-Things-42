#!/bin/bash
pkill -f "port-forward.*argocd"
k3d cluster delete dusty-cluster
