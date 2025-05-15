# 🚀 Step-by-Step Guide to Deploying a Kubernetes Cluster on Ubuntu with HAProxy
Welcome to the guide for setting up a Kubernetes cluster with an HAProxy load balancer! This document will walk you through the steps to configure HAProxy and ensure proper resolution of the API server address.  
#### **Tested on Ubuntu 20.04, 22.04 and 24.04 ✅**  
This guide has been successfully tested on **Ubuntu 20.04**, **Ubuntu 22.04** and **Ubuntu 24.04**, ensuring compatibility and smooth execution of all steps.

#### 📝 **Introduction**

Kubernetes is an open-source container orchestration system for automating software deployment, scaling, and management. Originally designed by Google, the project is now maintained by a worldwide community of contributors, and the trademark is held by the Cloud Native Computing Foundation.


### **Let's proceed with the installation step by step ✔️**

---

## 1️⃣ **Disable Swap Memory 🛑** 

Kubernetes schedules work based on the understanding of available resources. If workloads start using swap, it can become difficult for Kubernetes to make accurate scheduling decisions. Therefore, it’s recommended to disable swap before installing Kubernetes. Open the `/etc/fstab` file with a text editor. You can use nano, vim, or any other text editor you are comfortable with.

#### 🔹 **There are 2 ways to disable swap:**

### 1.1. **First way:**
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 1.2. **Second way:**
```bash
sudo vim /etc/fstab
```

Look for the line that references the swap file. It will usually look something like this:

```vim
/swapfile          none          swap          sw          0          0
```
Delete this line, then reboot the system.

#### 💡 **Note:** 
To allow kubelet to work properly, we need to disable swap on both machines (Master and Worker nodes).

---

## 2️⃣ **Set up the IPv4 Bridge Networking on All Nodes** 🌉

To configure the IPv4 bridge on all nodes, execute the following commands on each node.

#### 🔹 **Load the `br_netfilter` module required for networking:**
```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```
To allow iptables to see bridged traffic, as required by Kubernetes, we need to set the values of certain fields to 1.


#### 🔹 **Set sysctl parameters to allow iptables to see bridged traffic:**
```bash
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```

#### 🔹 **Apply sysctl parameters without reboot:**
```bash
sudo sysctl --system
```

---

## 3️⃣ **Install Container Runtime (Containerd)** 🐳
Kubernetes requires a container runtime to manage containers.

#### 🔹 **Install containerd:**
```bash
sudo apt install containerd -y
```

#### 🔹 **Set up the default configuration file:**
```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

#### 🔹 **Modify the containerd configuration file:**
Edit the following file:
```bash
sudo vim /etc/containerd/config.toml
```
Search for the section in the file that starts with `plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options` and locate the `SystemdCgroup` setting. Change `SystemdCgroup=false` to `true`:

```bash
SystemdCgroup = true
```

#### 🔹 **Restart containerd to apply changes:**
```bash
sudo systemctl restart containerd
```

---

## 4️⃣ **Install Kubernetes Tools (kubeadm, kubelet, kubectl)** 🛠️

Let’s install `kubelet`, `kubeadm`, and `kubectl` on each node to create a Kubernetes cluster. These components are essential for managing and operating a Kubernetes cluster.

#### 🔸 **`Kubeadm`** : The command to bootstrap the cluster.  
#### 🔸 **`Kubelet`** : The component that runs on all machines in your cluster and starts pods and containers.  
#### 🔸 **`Kubectl`** : The command-line utility to interact with your cluster.

#### ⚠️ **These instructions are for Kubernetes v1.33.**

### 4.1. **Update the apt package index and install dependencies:**
```bash
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

### 4.2. **Download the public signing key for Kubernetes:**
```bash
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

#### 💡 Note: 
 In releases older than Debian 12 and Ubuntu 22.04, directory `/etc/apt/keyrings` does not exist by default, and it should be created before the curl command.
### 4.3. **Add the Kubernetes apt repository:**
```bash
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

### 4.4. **Install kubelet, kubeadm, and kubectl:**
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 4.5. **Enable the kubelet service:**
```bash
sudo systemctl enable --now kubelet
```
The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

### 4.6. **Enable the kubelet service so we can start it:**
```bash
sudo systemctl enable kubelet
```

### 4.7. **Run the following command on the master node to allow Kubernetes to fetch the required images before cluster initialization:**
```bash
sudo kubeadm config images pull
```

### 4.8. **Initialize the Cluster:**
### 💡 Important: *Before initializing the cluster, you must configure HAProxy first.* ❗️❗️❗️

```bash
kubeadm init --control-plane-endpoint "apisrv.aranetco.ir:8443" --pod-network-cidr=10.244.0.0/16 --upload-certs
```
#### ⚠️ **If the cluster doesn’t work, reset it with kubeadm:**
```bash
sudo kubeadm reset --force
```

To manage the cluster, configure `kubectl` on the master node. Create the `.kube` directory in your home directory and copy the cluster's admin configuration to your personal `.kube` directory. Then, change the ownership of the copied configuration file to give the user permission to use it:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Alternatively, if you are the root user, you can run:
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```


---

## 5️⃣ **Install Flannel** 🌐

Flannel is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes.

#### 🔹 **Deploy Flannel with `kubectl`:**
```bash
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

#### ⚠️ **Warning:**  
If you use a custom podCIDR (not `10.244.0.0/16`), you first need to download the above manifest and modify the network to match your configuration.  
For example, if your custom podCIDR is `192.168.0.0/16`, modify the network configuration in the downloaded manifest to match this range.

---

## 6️⃣ **Kubectl Autocompletion** ⌨️

#### **BASH:**
```bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

#### **ZSH:**
```bash
source <(kubectl completion zsh)
echo '[[ $commands[kubectl] ]] && source <(kubectl completion zsh)' >> ~/.zshrc
```

#### **FISH:**
For `FISH` shell, ensure you are using kubectl version 1.23 or above. Then, run the following command:
```bash
echo 'kubectl completion fish | source' > ~/.config/fish/completions/kubectl.fish && source ~/.config/fish/completions/kubectl.fish
```

---

## 7️⃣ **Join Worker Node to Cluster** 🤝

#### 🔹 **Run the `kubeadm join` command on each worker node to connect it to the control plane (master node):**
```bash
sudo kubeadm join [master-node-ip]:8443 --token [token] \
             --discovery-token-ca-cert-hash sha256:[hash]
```
---
### 🚀 [Deploying a Kubernetes Worker Node: Step-by-Step Guide](https://github.com/alirahmti/Kubernetes/blob/main/worker-node-setup.md)

1. **🚀 Prerequisites 🛠️**
2. **🛑 Disable Swap Memory**
3. **🌉 Set up the IPv4 Bridge Networking on All Nodes**
4. **🐳 Install Container Runtime (Containerd)**
5. **🛠️ Install Kubernetes Tools (kubeadm, kubelet, kubectl)**
6. **🤝 Join the Worker Node to the Cluster**
7. **✅ Verify the Node Addition**
8. **🌐 (Optional) Rebalance CoreDNS Pods**
9. **🎉 Congratulations!**

**💡 Hint:** This guide provides a **detailed, step-by-step explanation** for setting up and configuring a Kubernetes worker node from scratch. **👉 Click the title above** or [**here**](https://github.com/alirahmti/Kubernetes/blob/main/worker-node-setup.md) to access the full guide.

---
## **8️⃣ HAProxy** 🚀

#### 📝 **Introduction**  
HAProxy, which stands for **High Availability Proxy**, is a popular open-source software solution for **TCP/HTTP load balancing** and proxying. It can run on Linux, macOS, and FreeBSD. Its primary purpose is to improve the **performance** and **reliability** of a server environment by distributing workloads across multiple servers (e.g., web, application, or database servers).  

HAProxy is widely used in high-profile environments, including **GitHub**, **Imgur**, **Instagram**, and **Twitter**. 🌐

---

#### **Installation ✔️**  
To install HAProxy on Ubuntu, use the following command:  
```bash
apt install haproxy
```  

Once installed, you can configure HAProxy by editing its configuration file:  
```bash
vim /etc/haproxy/haproxy.cfg
```  

Below is the full configuration for HAProxy:  

---

### **HAProxy Configuration File** 🛠️
```haproxy
# Frontend for Kubernetes API
frontend k8s-api
  bind *:8443
  mode tcp
  option tcplog
  default_backend k8s-api

# Backend for Kubernetes API
backend k8s-api
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server k8s-api-1 192.168.168.51:6443 check

# Monitoring HAProxy
frontend stats
  bind *:8404
  stats enable
  stats uri /stats
  stats refresh 10
```

---

### **Explanation of the Configuration File** 📝  

#### **1. Frontend for Kubernetes API**  
- **`frontend k8s-api`**: Defines a frontend named `k8s-api` to handle incoming traffic.  
- **`bind *:8443`**: Binds the frontend to port `8443` on all available network interfaces. 🌐  
- **`mode tcp`**: Configures the frontend to operate in **TCP mode** (Layer 4), which is suitable for Kubernetes API traffic.  
- **`option tcplog`**: Enables detailed logging for TCP connections. 📝  
- **`default_backend k8s-api`**: Specifies that traffic received on this frontend should be forwarded to the `k8s-api` backend.  

#### **2. Backend for Kubernetes API**  
- **`backend k8s-api`**: Defines a backend named `k8s-api` to handle traffic forwarded from the frontend.  
- **`mode tcp`**: Configures the backend to operate in **TCP mode**.  
- **`option tcplog`**: Enables detailed logging for TCP connections.  
- **`option tcp-check`**: Enables health checks for backend servers using TCP. ✅  
- **`balance roundrobin`**: Distributes traffic evenly across all available servers in a **round-robin** fashion. 🔄  
- **`default-server`**: Sets default parameters for all servers in this backend:  
  - **`inter 10s`**: Interval between health checks is 10 seconds.  
  - **`downinter 5s`**: Interval between health checks for servers marked as down is 5 seconds.  
  - **`rise 2`**: A server is marked as healthy after 2 consecutive successful health checks.  
  - **`fall 2`**: A server is marked as unhealthy after 2 consecutive failed health checks.  
  - **`slowstart 60s`**: Gradually increases the server's weight over 60 seconds after it becomes healthy.  
  - **`maxconn 250`**: Limits the maximum number of concurrent connections to 250 per server.  
  - **`maxqueue 256`**: Limits the maximum number of queued connections to 256 per server.  
  - **`weight 100`**: Assigns a weight of 100 to the server for load balancing.  
- **`server k8s-api-1 192.168.168.51:6443 check`**: Defines a backend server named `k8s-api-1` with the IP address `192.168.168.51` and port `6443`. The `check` option enables health checks for this server.  

#### **3. Monitoring HAProxy**  
- **`frontend stats`**: Defines a frontend named `stats` for monitoring HAProxy. 📊  
- **`bind *:8404`**: Binds the monitoring interface to port `8404` on all available network interfaces.  
- **`stats enable`**: Enables the HAProxy statistics module.  
- **`stats uri /stats`**: Specifies the URI path (`/stats`) for accessing the statistics page.  
- **`stats refresh 10`**: Refreshes the statistics page every 10 seconds. 🔄  
---


##  **9️⃣ Configuring API Server Address ⚙️**  

When setting up your Kubernetes cluster, it is essential to ensure that the **API server address** is properly resolved by all machines in the cluster, including the master and worker nodes. This can be achieved in one of two ways:  

---

### 🌐 **1. Using a DNS Server (Recommended)**  
If you have a **DNS server** configured, you should add the API server's address to the DNS records. This allows all nodes and clients in the cluster to resolve the API server's domain name to its IP address automatically.  

For example, you would create a DNS record that maps the API server's domain name (e.g., `api-server.example.com`) to its IP address (e.g., `192.168.1.50`).  

✅ **Advantages of Using DNS:**  
- Centralized domain name resolution.  
- Simplifies management, especially in larger or dynamic environments.  

---

### 🖥️ **2. Using the `/etc/hosts` File (When DNS is Not Available)**  
If you do not have a DNS server, you must manually configure the API server's domain name resolution by adding an entry to the `/etc/hosts` file on **all machines associated with the Kubernetes cluster**, including the master and worker nodes.  

#### **Steps to Configure `/etc/hosts`:**  
1. Open the `/etc/hosts` file on each machine:  
   ```bash
   sudo vim /etc/hosts
   ```

2. Add the following line to map the API server's IP address to its domain name:  
   ```bash
   192.168.1.50 api-server.example.com
   ```
   - Replace `192.168.1.50` with the **IP address** of your API server.  
   - Replace `api-server.example.com` with the **desired domain name**.  

3. Save and close the file.  

---

### ❗ **Important Note**  
When you are not using a DNS server, you **must include the domain name and API address of the API server in the `/etc/hosts` file on all machines in the Kubernetes cluster**, including the master and worker nodes. This ensures that all nodes can resolve the API server's domain name to its IP address.  

---

## 📋 **Why This Step is Important**  

- **DNS Server**: Using a DNS server is the preferred method because it centralizes domain name resolution and simplifies management, especially in larger or dynamic environments.  
- **`/etc/hosts` File**: This method is suitable for smaller setups or testing environments but requires manual updates on each machine if the API server's IP address changes.  

---

### 🎉 **You're All Set!**  
Now that you've configured the API server address, you're ready to proceed with initializing your Kubernetes cluster and setting up HAProxy. 🚀  

---

## 🌟 **Why Use Port 8443 for HAProxy Instead of 6443 for the Kubernetes API Server?**

When setting up a Kubernetes cluster with HAProxy as a load balancer, you may notice that the Kubernetes API server listens on **port 6443** by default, but HAProxy is configured to listen on **port 8443**. This is a deliberate and important design choice. Here's why:

---

### 🔧 **1. Separation of Responsibilities**
- **Port 6443** is the default port used by the Kubernetes API server for secure communication.  
- HAProxy acts as an **intermediary** (load balancer) between clients (e.g., `kubectl`, Kubernetes components, or external users) and the API server.  
- To avoid confusion and clearly distinguish between **direct API server access** and **load-balanced access**, HAProxy is configured to listen on **port 8443**.

---

### 🚫 **2. Avoiding Port Conflicts**
- If HAProxy were configured to listen on **port 6443**, it would conflict with the Kubernetes API server, which is already bound to that port on the master node(s).  
- By using **port 8443**, we ensure that both services (HAProxy and the Kubernetes API server) can coexist without any port binding issues.

---

### 🌐 **3. HAProxy as a Gateway**
- HAProxy serves as a **single entry point** for all incoming traffic to the Kubernetes API server.  
- By assigning it a different port (**8443**), it becomes clear that traffic on this port is being routed through the load balancer.  
- This abstraction simplifies client configuration, as clients only need to know the HAProxy endpoint (e.g., `https://haproxy.example.com:8443`) rather than managing multiple API server endpoints.

---

### 🔒 **4. Security and Access Control**
- Using a different port for HAProxy allows for better **access control** and **firewall rules**:  
  - **Port 6443** can be restricted to internal components or administrators who need direct access to the API server.  
  - External users or clients can be directed to **port 8443**, where HAProxy handles load balancing and potentially additional security measures (e.g., rate limiting, logging).

---

### ⚖️ **5. Flexibility in Multi-Master Setups**
- In a **multi-master Kubernetes cluster**, HAProxy distributes traffic across multiple API servers running on different master nodes.  
- By using **port 8443**, HAProxy provides a **single, unified entry point** for clients, while internally forwarding requests to the appropriate master node on **port 6443**.

---

### 🛠️ **How It Works in Your Configuration**
Here’s how this setup is reflected in your HAProxy configuration:

```haproxy
# Frontend for Kubernetes API
frontend k8s-api
  bind *:8443  # HAProxy listens on port 8443 for incoming traffic
  mode tcp
  option tcplog
  default_backend k8s-api

# Backend for Kubernetes API
backend k8s-api
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  server k8s-api-1 192.168.1.50:6443 check  # Forwards traffic to the API server on port 6443
```

- **Frontend (`bind *:8443`)**: HAProxy listens for incoming traffic on **port 8443**.  
- **Backend (`192.168.1.50:6443`)**: HAProxy forwards the traffic to the Kubernetes API server running on **port 6443**.

This setup ensures that:  
1. Clients connect to HAProxy on **port 8443**.  
2. HAProxy distributes the traffic to the API server(s) on **port 6443**.

---

### 🎯 **Key Benefits of Using Port 8443 for HAProxy**
1. **No Port Conflicts**: Avoids conflicts with the Kubernetes API server, which uses port 6443.  
2. **Clear Separation**: Distinguishes between direct API server access and load-balanced access.  
3. **Simplified Access**: Provides a single, unified entry point for clients.  
4. **Enhanced Security**: Allows for better access control and firewall rules.  
5. **Scalability**: Supports multi-master setups by routing traffic to multiple API servers.

---

### 🎉 **Conclusion**
Using **port 8443** for HAProxy instead of **port 6443** is a best practice that ensures a clean, scalable, and secure architecture for your Kubernetes cluster. It avoids conflicts, simplifies management, and provides a clear separation of responsibilities between HAProxy and the Kubernetes API server. 🚀


---
## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
