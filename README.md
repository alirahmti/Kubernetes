# 🚀 Step-by-Step Guide to Deploying a Kubernetes Cluster on Ubuntu
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

### 4.7. **Run the following command on the master node to allow Kubernetes to fetch the required images before cluster initialization:**
```bash
sudo kubeadm config images pull
```

### 4.8. **Initialize the Cluster:**
```bash
kubeadm init --control-plane-endpoint "<FQDN or IPAddress>:6443" --pod-network-cidr=10.244.0.0/16 --upload-certs
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

## **Generating a New Join Command for a Worker Node** 🧑‍🏭

If you've lost the join command for your Kubernetes worker node, you can easily generate a new token and the corresponding join command on your control plane (master) node.

#### 🔹 **Generate a new token and join command:**
```bash
kubeadm token create --print-join-command
```

#### 🔹 **Run the join command on the worker node:**
```bash
sudo kubeadm join <control_plane_IP>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```



## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!

