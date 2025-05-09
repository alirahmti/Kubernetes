### 🚀 Step-by-Step Guide to Deploying a Kubernetes Worker Node

Here’s a polished and detailed explanation of the steps to deploy a worker node in a Kubernetes cluster, from scratch to completion. I’ve corrected any errors and added some flair with emojis to make it engaging and easy to follow!

---

## **1️⃣ Prerequisites 🛠️**
Before starting, ensure you have:
- A **Kubernetes control plane (master node)** already set up.
- A new **worker node** (Ubuntu 20.04 or later recommended) with:
  - At least **2 CPUs**, **2 GB RAM**, and **20 GB disk space**.
  - **SSH access** and **sudo privileges**.
  - Networking configured between the worker node and the control plane.

---

## **2️⃣ Disable Swap Memory 🛑**
Kubernetes schedules work based on the understanding of available resources. If workloads start using swap, it can become difficult for Kubernetes to make accurate scheduling decisions. Therefore, it’s recommended to disable swap before installing Kubernetes. Open the `/etc/fstab` file with a text editor. You can use nano, vim, or any other text editor you are comfortable with.

#### 🔹 **There are 2 ways to disable swap:**

### 2.1. **First way:**
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 2.2. **Second way:**
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

## 3️⃣ **Set up the IPv4 Bridge Networking on All Nodes** 🌉

To configure the IPv4 bridge on all nodes, execute the following commands on each node.

####  **🔹Load the `br_netfilter` module required for networking:**
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

## **4️⃣ Install Container Runtime (Containerd) 🐳**
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

## **5️⃣ Install Kubernetes Tools (kubeadm, kubelet, kubectl) 🛠️**
Let’s install `kubelet`, `kubeadm`, and `kubectl` on each node to create a Kubernetes cluster. These components are essential for managing and operating a Kubernetes cluster.

#### 🔸 **`Kubeadm`** : The command to bootstrap the cluster.  
#### 🔸 **`Kubelet`** : The component that runs on all machines in your cluster and starts pods and containers.  
#### 🔸 **`Kubectl`** : The command-line utility to interact with your cluster.

#### ⚠️ **These instructions are for Kubernetes v1.30.**

### 4.1. **Update the apt package index and install dependencies:**
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

### 4.2. **Download the public signing key for Kubernetes:**
```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
#### 💡 Note: 
 In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, and it should be created before the curl command.
### 4.3. **Add the Kubernetes apt repository:**
```bash
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

---

## **6️⃣ 🧑‍💻 Generating a New Join Command for a Kubernetes Worker Node 🤝**
If you've lost the join command for your Kubernetes worker node, don’t worry! You can easily generate a new token and the corresponding join command on your control plane (master) node. Follow these steps:

---

### **6.1. Generate a New Token and Join Command**  
Run the following command on your control plane node to create a new token and print the join command:

```bash
kubeadm token create --print-join-command
```

This command will output something like:

```bash
kubeadm join <control_plane_IP>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

- `<control_plane_IP>`: The IP address of your control plane node.  
- `<token>`: The newly generated token.  
- `<hash>`: The discovery token CA certificate hash.

---

### **6.2. Run the Join Command on the Worker Node**  
Take the output from the previous step and run the complete join command on your worker node. For example:

```bash
sudo kubeadm join <control_plane_IP>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

---

### **💡 Important Notes**  
- **Token Validity**: 🔸 By default, the token is valid for **24 hours**. If you need to join a worker node after this period, you will need to generate a new token as described above.  
- **Ensure Connectivity**: 🔸 Make sure your worker node can reach the control plane node over the network.  

⚠️ **This process will allow you to successfully rejoin your worker node to the Kubernetes cluster.** ⚠️  

---

## **7️⃣ Verify the Node Addition ✅**
On the control plane node, check if the worker node has joined successfully:
```bash
kubectl get nodes
```
You should see the new worker node listed with a `Ready` status.

---

## **8️⃣ (Optional) Rebalance CoreDNS Pods 🌐**
If CoreDNS pods are running only on the control plane node, rebalance them:
```bash
kubectl -n kube-system rollout restart deployment coredns
```

---

### **🎉 Congratulations!**
Your worker node is now part of the Kubernetes cluster and ready to run workloads. 🚀

## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
