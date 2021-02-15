#!/bin/bash
kubectl get configmap -n kube-system kube-proxy -o yaml > ~/kube-proxy-configmap.yaml
sed -i 's/strictARP: false/strictARP: true/' ~/kube-proxy-configmap.yaml
kubectl apply -f ~/kube-proxy-configmap.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.3/manifests/metallb.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

kubectl apply -f /opt/metallb-config.yaml