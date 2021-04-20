# Metodología GitOps para despliegue de aplicaciones basadas en microservicios
>Código del TFG de Francisco Maderuelo, perteneciente a los estudios de **Grado en Tecnologías para la Sociedad de la Información** de la **ETSISI - UPM**.

## Requisitos
* **[VirtualBox](https://www.virtualbox.org/wiki/Downloads)** - Probado con la versión 6.1.18
* **[Vagrant](https://www.vagrantup.com/downloads)** - Probado con la versión 2.2.14
* **[vagrant-hostmanager](https://github.com/devopsgroup-io/vagrant-hostmanager)** plugin - Probado con la versión 1.8.9
```
vagrant plugin install vagrant-hostmanager
```
## Diagrama

![Diagrama](/images/k8s-cluster.png)

## Máquinas virtuales desplegadas
Se despliegan en total 5 máquinas virtuales (nodos): 2 master y 3 worker, y se instala etcd en 3 de ellos para asegurar la alta disponibilidad del mismo.

El detalle de la configuración de las MVs que se crearán es:

| |masters|workers
-----|-----|-----
nº de nodos|2|3
vcpu (por nodo)|2|2
memoria (por nodo)|4 Gb| 3 Gb
disco sda|40 Gb|40 Gb
disco sdb|20 Gb|20 Gb

## INSTALACIÓN
### Clonar el proyecto y crear la infraestructura
```
git clone https://github.com/fmaderuelo/tfg-gitops.git
cd tfg-gitops
vagrant up
```
### Conectarse a master-1 y preparar los nodos
```
vagrant ssh master-1
sudo su
cd /root/kubespray_installation/
ansible-playbook -i inventories/bastion playbooks/prepare_bastion.yaml
ansible-playbook -i /root/kubespray/inventory/mycluster/inventory.ini playbooks/prepare_nodes.yaml

```
### Instalar Kubernetes
```
sudo su -
cd /root/kubespray
pip3 install -r requirements.txt
ansible-playbook -i /root/kubespray/inventory/mycluster/inventory.ini --become --become-user=root cluster.yml
```
Si todo ha ido bien el resultado será parecido a esto:

![Instalacion](/images/k8s-installation.png)

### Dar acceso al clúster mediante *kubectl*
```
sh /opt/postinstall.sh
source ~/.bashrc
k cluster-info
k get nodes
```
La ejecución del último comando debería mostrar algo similar a lo siguiente:

![Nodos](/images/k8s-nodes.png)

### Instalar y configurar *MetalLB*
```
sh /opt/metallb-install.sh
```
### Instalar *Helm*
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
### Configurar el almacenamiento persistente
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=10.61.1.11 --set nfs.path=/datos
```
Como parte de la instalación se genera la *StorageClass* **nfs-client**, que se puede establecer como la clase por defecto mediante:
```
kubectl patch storageclasses.storage.k8s.io nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
### Instalar el servidor de métricas
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.2/components.yaml
kubectl patch deployments.apps metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```
### Instalar un *ingress-controller*
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```
### Instalar *Kubernetes Dashboard*
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl apply -f /opt/k8s-dashboard.yaml
```
Obtener el token de la *ServiceAccount*:
```
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```
Desde el directorio donde está el *Vagrantfile* en el host, descargar el archivo de configuración del clúster y modificar la dirección de conexión por la ip de *master-1*:
```
scp -i .vagrant/machines/master-1/virtualbox/private_key vagrant@10.61.1.11:/home/vagrant/.kube/config .
sed -i 's/127.0.0.1:6443/10.61.1.11:6443/' config
```
Configurar *kubectl* en el host para que use el archivo de configuración y crear un proxy entre el host y el clúster:
```
export KUBECONFIG=config
kubectl proxy
```
Mientras el comando `kubectl proxy` se está ejecutando, el proxy está activo (se puede parar con CTRL + C). Con el proxy activo se puede acceder al dashboard desde un navegador del host en la dirección:

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Se puede utilizar el *ingress-controller* instalado para dar acceso al dashboard así:
```
kubectl apply -f /opt/dashboard-ingress.yaml
```
Y comprobar que se ha creado correctamente:
```
kubectl get ingresses.networking.k8s.io -n kubernetes-dashboard
```
Si todo ha ido bien, se podrá acceder al dashboard en la siguiente dirección:

https://dashboard.10.61.1.30.xip.io

Y después de introducir el token se verá algo parecido a esto:

![Dashboard](/images/dash-ingress.png)
### Instalar Argo CD
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v1.8.5/manifests/install.yaml
```
Obtener la contraseña inicial de Argo CD:
```
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```
Modificar el *Deployment* de argocd-server para aceptar conexiones no seguras:
```
kubectl patch deployments.apps argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--insecure"}]'
```
Y crear el objeto *Ingress* para Argo CD:
```
kubectl apply -f /opt/argocd-ingress.yaml
```
Una vez creado se podrá acceder desde el navegador del host en la dirección:

http://argocd.10.61.1.30.xip.io