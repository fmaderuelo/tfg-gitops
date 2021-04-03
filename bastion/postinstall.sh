#!/bin/bash
## Configure kubectl for user and create alias "k" with completion capabilities
mkdir ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
sudo chmod 600 ~/.kube/config

echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# red color prompt
echo "PS1='\[\e[1;31m\][\u@\h \W]\$\[\e[0m\] '" >> ~/.bashrc