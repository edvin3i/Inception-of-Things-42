#!/bin/bash

pkill -f "port-forward"
k3d cluster delete serious-cluster
