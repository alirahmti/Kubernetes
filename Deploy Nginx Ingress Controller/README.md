
# 🚀 Deploy NGINX Ingress Controller on Kubernetes Cluster 


### 📝 **Introduction**

The **NGINX Ingress Controller** consists of two main components: a **Pod** and a **Service**.

- The **Pod** runs the Controller, which continuously polls the `/ingresses` endpoint on the Kubernetes API server for updates to available Ingress resources.
- The **Service** is of type `LoadBalancer`, which exposes the Ingress Controller to external traffic.

💡 **Key Note**:  
The `LoadBalancer` Service automatically creates a Load Balancer and assigns it an IP address. Some applications (like **ExternalDNS**) may require this IP address but can only read the configuration of an Ingress. To make the IP address available, you can enable the `controller.publishService.enabled` parameter during installation. This is highly recommended for applications that depend on the Load Balancer's IP address.

---

## 🛠️ **Installation Steps**

### 1️⃣ **Installing Helm**
First, install Helm (if you don’t already have it installed):
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

### 2️⃣ **Add the NGINX Ingress Helm Repository**
Add the official NGINX Ingress Controller Helm repository:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

---

### 3️⃣ **Update Helm Repositories**
Update your Helm repositories to fetch the latest charts:
```bash
helm repo update
```

---

### 4️⃣ **Generate a Helm Template**
Generate a Helm template for the NGINX Ingress Controller with the `controller.publishService.enabled` parameter set to `true`:
```bash
helm template nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true > nginx-ingress-controller.yml
```

---

### 5️⃣ **Install the NGINX Ingress Controller**
Install the NGINX Ingress Controller using Helm:
```bash
helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true
```

💡 **Explanation**:  
This command installs the NGINX Ingress Controller from the official Helm chart repository, names the Helm release `nginx-ingress`, and enables the `publishService` parameter to make the Load Balancer's IP address available.

---

### 6️⃣ **Customize Deployment with 2 Replicas**
If you want to customize the deployment (e.g., set the number of replicas to 2), follow these steps:

#### 🔹 **Step 1: Create a Namespace**
Create a namespace for the deployment:
```bash
kubectl create namespace ingress-nginx
```

#### 🔹 **Step 2: Edit the YAML File**
You can use the pre-generated YAML file or download the one I’ve provided on GitHub.  
👉 **Download the YAML file**:
```bash
curl -O https://raw.githubusercontent.com/alirahmti/Kubernetes/refs/heads/main/Deploy%20Nginx%20Ingress%20Controller/nginx-ingress-controller.yml
```

Open the `nginx-ingress-controller.yml` file and set the `replicas` field to `2` in the Deployment section:
```yaml
spec:
  replicas: 2
```

#### 🔹 **Step 3: Apply the YAML File**
Deploy the customized YAML file to the `devops` namespace:
```bash
kubectl apply -f nginx-ingress-controller.yml -n ingress-nginx
```

---

## 📂 **GitHub Configuration File**
You can find the full configuration file for the NGINX Ingress Controller on my GitHub:  
🔗 [nginx-ingress-controller.yml](https://raw.githubusercontent.com/alirahmti/Kubernetes/refs/heads/main/Deploy%20Nginx%20Ingress%20Controller/nginx-ingress-controller.yml)

Feel free to download and modify it as needed for your cluster setup.

---

## 🎯 **Final Notes**

- 🛡️ **Namespace Isolation**: Deploying the Ingress Controller in a dedicated namespace (like `devops`) helps isolate it from other workloads in your cluster.
- 🔄 **Scaling**: You can scale the Ingress Controller dynamically by updating the `replicas` field in the Deployment or using the `kubectl scale` command:
  ```bash
  kubectl scale deployment nginx-ingress-ingress-nginx-controller --replicas=3 -n devops
  ```
- 📜 **Logs**: To troubleshoot or monitor the Ingress Controller, check its logs:
  ```bash
  kubectl logs -l app.kubernetes.io/name=ingress-nginx -n devops
  ```

---

### 🎉 **Congratulations!**
You’ve successfully deployed the **NGINX Ingress Controller** on your Kubernetes cluster using Helm! 🚀  😊



## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
