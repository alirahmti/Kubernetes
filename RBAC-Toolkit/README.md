# 🔐 Kubernetes RBAC User Creation Toolkit

This repo includes **two fully-automated bash scripts** to generate RBAC users for Kubernetes via ServiceAccounts, tokens, and kubeconfig generation.

> Supports secure role assignment, namespace isolation, and different permission levels – ready for production, automation, and CI/CD usage.


## ✳️ Script 1: `create-rbac-user-advanced.sh`

A fully-interactive script that asks for:
- ✅ Username
- ✅ Target Namespace
- ✅ Kubernetes API endpoint (e.g., `https://apisrv.example.com:8443`)
- ✅ Access Level: `read-only`, `read-write`, or `admin`

### 🧰 How It Works

It will:
1. Create the namespace (if not exists)
2. Create a ServiceAccount for the user
3. Define a Role based on your access level
4. Bind the Role to the ServiceAccount
5. Create a secret token for the SA
6. Generate a ready-to-use `kubeconfig-<username>.yaml`

### 🔑 Access Level Definitions

| Access Level | Permissions |
|--------------|-------------|
| **read-only** | Can only view Pods, Services, and Deployments |
| **read-write** | Can create, update, delete, and view Pods, Services, Deployments |
| **admin** | Full access to **all** resources in the given namespace |


## 🔐 Script 2: `create-rbac-namespace-admin.sh`

This script gives **full administrative access** (verbs: `*`) to a given namespace.

### 🧰 Resources Included in Role:

- API groups: `"", apps, extensions, *`
- Resources: `"*"` (everything)
- Verbs: `"*"` (create, get, list, update, patch, delete...)

> This means the user can **manage all Kubernetes resources within the specified namespace.**

---

## 🧩 Add More Resources (Optional - Advanced)

Want to customize the Role for **specific resource types**? Here's what you can use:

| Resource | Description |
|----------|-------------|
| `pods` | Individual containers or workloads |
| `services` | Network abstraction to expose your apps |
| `deployments` | Declarative way to manage ReplicaSets and Pods |
| `configmaps` | Key-value pairs for non-confidential data |
| `secrets` | Key-value for confidential data (base64 encoded) |
| `persistentvolumeclaims` | Request for storage from available PVs |
| `jobs` | One-time Pod workloads |
| `cronjobs` | Scheduled recurring jobs |
| `replicasets` | Maintain a stable set of Pods |
| `ingresses` | HTTP routing to Services |
| `namespaces` | (⚠️ only with ClusterRole!) Create or delete namespaces |
| `roles` / `rolebindings` | Manage RBAC within namespace |
| `events` | Read Kubernetes events |
| `nodes` | (⚠️ only with ClusterRole!) Access to node-level info |
| `networkpolicies` | Control Pod-to-Pod network access |

> 🛑 To access **cluster-wide resources** like `nodes`, `namespaces`, or `clusterroles`, you need a **ClusterRole** instead of a namespace-specific Role.

## 📦 Example Output

At the end of execution, you’ll get a file:

```bash
kubeconfig-<username>.yaml
````

You can now use it with:

```bash
export KUBECONFIG=./kubeconfig-<username>.yaml
kubectl get pods
```

Or configure your `~/.kube/config` to include that context.

## ✅ How to Test Your `kubeconfig` File

After generating your `kubeconfig-<username>.yaml` file, you can test it using **two different methods**:


### 🔹 **Method 1: One-Line Command (Temporary Use)**

Use this if you just want to **run a single test command** without modifying your environment:

```bash
KUBECONFIG=./kubeconfig-<username>.yaml kubectl get pods
```

📌 This runs the command using your custom kubeconfig **just for that command** — nothing changes permanently.

### 🔸 **Method 2: Export KUBECONFIG (Session-Wide Use)**

If you want to run **multiple `kubectl` commands** using this kubeconfig without repeating the path every time:

```bash
export KUBECONFIG=./kubeconfig-<username>.yaml
```

Now you can run any `kubectl` command, and it will use the new config:

```bash
kubectl get pods
kubectl get svc
kubectl describe pod mypod
```

### 🧹 When You're Done: Reset to Default

To **revert back** and stop using the custom config, simply run:

```bash
unset KUBECONFIG
```

This will return your `kubectl` back to using the default config at:

```bash
~/.kube/config
```

You can verify the current kubeconfig being used with:

```bash
echo $KUBECONFIG
```

If it prints nothing, you're back to default ✅



## 📝 Requirements

* `kubectl` CLI configured and authenticated with admin access
* Kubernetes version 1.20+ (RBAC enabled)
* Bash environment

## 🚀 Usage (Quick Start)

```bash
chmod +x create-rbac-user-advanced.sh
./create-rbac-user-advanced.sh
```

OR

```bash
chmod +x create-rbac-namespace-admin.sh
./create-rbac-namespace-admin.sh
```



## ❤️ Contributing

PRs are welcome to:

* Add `ClusterRole` support
* Add template generator for Helm charts
* Integrate with GitOps tools like ArgoCD



## 🛡️ Disclaimer

These scripts are designed for namespace-level access. Use `ClusterRole` and `ClusterRoleBinding` **only** if you understand the full implications of granting cluster-wide access.




> ## 📝 About the Author
> #### Crafted with care and ❤️ by [Ali Rahmati](https://github.com/alirahmti). 👨‍💻
> If this repo saved you time or solved a problem, a ⭐ means everything in the DevOps world. 🧠💾
> Your star ⭐ is like a high five from the terminal — thanks for the support! 🙌🐧
