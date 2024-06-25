# Deploy Kubernetes Cluster on Ubuntu 20.04 

#### 📝 Introduction

Kubernetes is an open-source container orchestration system for automating software deployment, scaling, and management. Originally designed by Google, the project is now maintained by a worldwide community of contributors, and the trademark is held by the Cloud Native Computing Foundation.

### Installation ✔️

## 1. Disable Swap

Kubernetes schedules work based on the understanding of available resources. If workloads start using swap, it can become difficult for Kubernetes to make accurate scheduling decisions. Therefore, it’s recommended to disable swap before installing Kubernetes. Open the `/etc/fstab` file with a text editor. You can use nano, vim, or any other text editor you are comfortable
with.

#### There is 2 way for disable swap:
#### First way:

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

#### Second way:
```bash
sudo vim /etc/fstab
```

Look for the line that references the swap file. It will usually look something like this:

```vim
/swapfile          none          swap          sw          0          0
```
Delete this line, Then Reboot system.

#### Note: 💡
##### To allow kubelet to work properly, we need to disable swap on both machines (Master and worker nodes).

## 2. Set up the IPV4 bridge on all nodes

To configure the IPV4 bridge on all nodes, execute the following commands on each node.
Load the br_netfilter module required for networking

```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```
To allow iptables to see bridged traffic, as required by Kubernetes, we need to set the values of certain fields to 1.

sysctl params required by setup, params persist across reboots
```bash
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
```
 Apply sysctl params without reboot

```bash
sudo sysctl --system
```
## 3. Installing Containerd

```bash
sudo apt install containerd -y
```
Set up the default configuration file

```bash
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
```

Next up, we need to modify the containerd configuration file and ensure that the cgroupDriver is set to
systemd. To do so, edit the following file:
```bash
sudo vim /etc/containerd/config.toml
```
And search `plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options`, then change `SystemdCgroup=false` to `true`.

```bash
SystemdCgroup = true
```
Finally, to apply these changes, we need to restart containerd.

```bash
sudo systemctl restart containerd
```
## 4. Install kubelet, kubeadm, and kubectl
Let’s install kubelet, kubeadm, and kubectl on each node to create a Kubernetes cluster. They play an important
role in managing a Kubernetes cluster

You will install these packages on all of your machines:

🔸 Kubeadm : the command to bootstrap the cluster.

🔸 Kubelet : the component that runs on all of the machines in your cluster and does things like starting pods and containers.

🔸 Kubectl : the command line util to talk to your cluster

#### ⚠️ These instructions are for Kubernetes v1.30. ⚠️

### 4.1. Update the apt package index and install packages needed to use the Kubernetes apt repository:
```bash
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```
### 4.2. Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:

```bash
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
#### Note: 💡
##### In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, and it should be created before the curl command.

### 4.3. Add the appropriate Kubernetes `apt` repository.
 Please note that this repository have packages only for Kubernetes 1.30; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).
```bash
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
### 4.4. Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
### 4.5. (Optional) Enable the kubelet service before running kubeadm:

```bash
sudo systemctl enable --now kubelet
```
The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

### 4.6. Finally, enable the kubelet service so we can start it.
```bash
sudo systemctl enable kubelet
```
### 4.7. Run the following command on the master node to allow Kubernetes to fetch the required images before cluster initialization:
```bash
sudo kubeadm config images pull
```
### 4.8. Initialize Cluster


```bash
kubeadm init --control-plane-endpoint "<FQDN or IPAddress>:6443" --pod-network-cidr=10.244.0.0/16 --upload-certs
```
#### ⚠️ if cluster dosen't work, reset cluster with kubeadm: ⚠️
```bash
sudo kubeadm reset --force
```
To manage the cluster, you should configure kubectl on the master node. Create the `.kube` directory in your home directory and copy the cluster's admin configuration to your personal .kube directory. Next, change the `ownership` of the copied configuration file to give the user the permission to use the configuration file to interact with the cluster
```bash
mkdir -p $HOME/.kubemkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Alternatively, if you are the root user, you can run:
```bash
export KUBECONFIG=/etc/kubernetes/admin.conf
```
## 5. Install Flannel
Flannel is a simple and easy way to configure a layer 3 network fabric designed for Kubernetes.
Deploying Flannel with `kubectl` :
```bash
kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
```
### ⚠️ Warning ⚠️
#### If you use custom podCIDR (not 10.244.0.0/16 ) you first need to download the above manifest and modify the network to match your one.

## 6. Kubectl Autocompletion

### BASH
```bash
source <(kubectl completion bash) # set up autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
```
#### You can also use a shorthand alias for `kubectl` that also works with completion:
```bash
alias k=kubectl
complete -o default -F __start_kubectl k
```

### ZSH 
```bash
source <(kubectl completion zsh)  # set up autocomplete in zsh into the current shell
echo '[[ $commands[kubectl] ]] && source <(kubectl completion zsh)' >> ~/.zshrc # add autocomplete permanently to your zsh shell
```

### FISH
#### Note: 💡
##### Requires kubectl version 1.23 or above.
```bash
echo 'kubectl completion fish | source' > ~/.config/fish/completions/kubectl.fish && source ~/.config/fish/completions/kubectl.fish
```

## 7. Join Worker Node to Cluster
Apply the `kubeadm` join command on worker nodes to connect them to the master node. Prefix the command with `sudo` :

```bash
sudo kubeadm join [master-node-ip]:8443 --token [token] \
             --discovery-token-ca-cert-hash sha256:[hash]
```

## Deploy Worker node:

🔺Disable swap

🔺Set up the IPV4 bridge on all nodes

🔺Installing Containerd

🔺Install kubelet, kubeadm, and kubectl


