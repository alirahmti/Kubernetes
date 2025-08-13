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

#### 🔹 **Load the `br_netfilter` and `overlay` module required for networking:**
```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

The overlay and br_netfilter kernel modules are essential for Kubernetes networking and container runtime functionality.
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
## 5️⃣ **CNI plugins for Kubernetes networking 🌐**
### Currently, we have two CNI installation methods: `Flannel` and `Calico`. 

>These are just two of the many CNI options available for Kubernetes. 🔧 Depending on your network needs, you might find other CNI plugins that suit your use case even better! 💡 However, for this guide, we'll focus on these two options to keep things simple. Let's move forward with the installation based on your choice! 🚀


##  5.1. **Install Flannel 🌐**

Flannel is a simple and easy way to configure a Layer 3 network fabric designed for Kubernetes. It helps with pod networking and is suitable for most basic use cases. 🚀

#### 🔹 **Deploy Flannel with `kubectl`:**

```bash
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```

#### ⚠️ **Warning:**

If you use a custom `podCIDR` (not `10.244.0.0/16`), you first need to download the above manifest and modify the network to match your configuration.
For example, if your custom `podCIDR` is `192.168.0.0/16`, modify the network configuration in the downloaded manifest to match this range. 🌍



## 5.2. **Install Calico 🌐**

Calico is a powerful networking and network security solution for Kubernetes. It helps with pod networking, network policies, and much more. Calico is highly recommended for advanced use cases, especially when you need network security features. 🛡️

🔹 **Step 1: Create ServiceAccount & RoleBinding**:
Calico requires a ServiceAccount with the correct roles to interact with Kubernetes resources. Run the following commands to set up the permissions:

```bash
kubectl create serviceaccount calico-node -n kube-system
kubectl create clusterrolebinding calico-admin --clusterrole=cluster-admin --serviceaccount=kube-system:calico-node
```

🔹 **Step 2: Install Calico with `kubectl`:**
Now, you can install Calico using the following command:

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

#### ⚠️ **Warning:**

Ensure your Kubernetes nodes are properly configured to support Calico. If you're facing issues with pod connectivity, check firewall or CNI settings. 🔧


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

---
# 🚀 **How to Remove Kubernetes Cluster with kubeadm** 🛠️

In this final section, we’ll walk you through the steps to **completely remove your Kubernetes cluster** and all related configurations. This is helpful if you need to tear down your cluster to reset, reconfigure, or create a fresh Kubernetes setup.  🧹

   

### **Step-by-Step Guide to Remove Kubernetes Cluster** 🧹

When you want to start fresh or remove your cluster for any reason, follow these steps carefully. This guide will remove all Kubernetes-related components and configurations from your system.



### **Step 1: Reset Kubernetes Cluster with kubeadm** 🔄

To begin, we need to reset the Kubernetes cluster on **all nodes** (both Master and Worker nodes). Run the following command:

```bash
sudo kubeadm reset
```

This command will reset the cluster and remove most Kubernetes configurations. ✅


### **Step 2: Clean Up Kubernetes Files** 🧽

Next, remove all Kubernetes-related files and configurations from your system:

```bash
sudo rm -rf /etc/kubernetes
sudo rm -rf ~/.kube
sudo rm -rf /var/lib/etcd
```

This will clean up all cluster configurations and etcd data, leaving no residual Kubernetes files. 🧹



### **Step 3: Remove CNI Configurations** 🌐

If you're using a **CNI (Container Network Interface)** plugin (such as **Flannel** or **Calico**), you need to remove those configurations:

```bash
sudo rm -rf /etc/cni
```

This step will clean up any networking configurations set up by your Kubernetes network plugin. 🌐



### **Step 4: Disable and Stop kubelet** 🛑

Stop the `kubelet` service and disable it from starting automatically:

```bash
sudo systemctl stop kubelet
sudo systemctl disable kubelet
```

This ensures that the `kubelet` service is not running and will not restart when the system boots. 🔒



### **Step 5: Remove Network Interfaces** 🔧

Kubernetes or CNI plugins may add virtual network interfaces to the system. Remove them by running:

```bash
sudo ip link delete <interface-name>
```

Replace `<interface-name>` with the name of the interface you want to remove (e.g., `tunl0`, `cni0`). 💻


### **Step 6: Reboot the System** 🔄

Once you have cleaned up all Kubernetes components, it’s a good idea to reboot the system to ensure all changes are applied:

```bash
sudo reboot
```



### **Step 7: Verify Removal** ✅

After the reboot, verify that Kubernetes is no longer active on your nodes:

```bash
kubectl get nodes
```

If the cluster is removed properly, you should see no nodes listed. 👀


### **Step 8: Reinitialize the Kubernetes Cluster** 🔄

If you're ready to reinitialize your Kubernetes cluster, you can follow the [Kubernetes setup guide](https://github.com/alirahmti/Kubernetes) for instructions. Whether you're setting up a fresh cluster or testing something new, the guide will help you get your cluster up and running in no time! 😄



### 🎉 **Congratulations! You've Successfully Removed Your Kubernetes Cluster!** 🎉

With this, you have a completely fresh environment, ready to be reinitialized, reconfigured, or simply removed from the system. 🔥

This concludes the Kubernetes removal steps. If you need further assistance or have questions about reinstalling or configuring a new cluster, feel free to check other sections of the Kubernetes setup guide or reach out for help!

**Happy Kubernetes-ing!** 🚀
---
> ## 📝 About the Author
> #### Crafted with care and ❤️ by [Ali Rahmati](https://github.com/alirahmti). 👨‍💻
> If this repo saved you time or solved a problem, a ⭐ means everything in the DevOps world. 🧠💾
> Your star ⭐ is like a high five from the terminal — thanks for the support! 🙌🐧
