# Deploy Nginx Ingress Controller on Kubernetes Cluster 

#### 📝 Introduction

The Nginx Ingress Controller consists of a Pod and a Service. The Pod runs the Controller, which constantly polls the `/ingresses` endpoint on the API server of your cluster for updates to available Ingress Resources. The Service is of type `LoadBalancer`. 

Only the LoadBalancer Service knows the IP address of the automatically created Load Balancer. Some apps (such as ExternalDNS) will need to know its IP address but can only read the configuration of an Ingress. The Controller can be configured to publish the IP address on each Ingress by setting the `controller.publishService.enabled` parameter to `true` during `helm install`. It is recommended to enable this setting to support applications that may depend on the IP address of the Load Balancer.


## Installation ✔️
### Installing Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
#### 🔸 To install the Nginx Ingress Controller to your cluster, you’ll first need to add its repository to Helm by running:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

#### 🔸 Update your system to let Helm know what it contains:

```bash
helm repo update
```
#### 🔸 Generate helm template:

```bash
helm template nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true > nginx-ingress-controller.yml
```
#### 🔸 Finally, run the following command to install the Nginx ingress:

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true
```
#### 🔸 This command installs the Nginx Ingress Controller from the stable charts repository, names the Helm release nginx-ingress, and sets the publishService parameter to true.

#### 💡 But we want to change replicas to 2 and deploy yml file. First we must create `devops` namespace and set `replicas: 2`, then apply yml file.
```bash
kubectl create namespace devops
kubectl apply -f nginx-ingress-controller.yml -n devops
```