# 🔐 Kubernetes RBAC User Creation Toolkit

This directory includes **two fully-automated bash scripts** to generate RBAC users for Kubernetes using `ServiceAccounts`, tokens, and `kubeconfig` files — with full support for custom access controls.

> ✅ Ideal for DevOps, GitOps, CI/CD pipelines, and production-grade environments.


## ✳️ Script 1: `create-rbac-user-advanced.sh`

🎛️ A fully-interactive **RBAC user generator** that supports four access modes:

- 👤 Custom username input  
- 📦 Namespace isolation  
- 🌐 API Server endpoint  
- 🔐 Access Level:  
  - `read-only`
  - `read-write`
  - `admin`
  - `custom` (your own resource/verb matrix)


### 🧰 How It Works

This script will:

1. 🔎 Check if namespace exists (creates it if not)
2. 👤 Create a ServiceAccount for the user
3. 📜 Create a Role (based on chosen access level)
4. 🔗 Bind Role to the ServiceAccount
5. 🔑 Create a token Secret
6. 📄 Generate a ready-to-use `kubeconfig-<username>.yaml`



### 🔑 Access Level Definitions

| Access Level | Permissions |
|--------------|-------------|
| **read-only** | Can only view Pods, Services, and Deployments |
| **read-write** | Can create, update, delete, and view Pods, Services, Deployments |
| **admin** | Full access to **all** resources in the specified namespace |
| **custom** | 🎯 You choose exactly **which resources** and **what kind of access (verbs)** you want per resource |


### 🔧 How `custom` Access Works

When selecting the `custom` option, you’ll be asked to:
1. ✅ Choose one or more resources from a list (e.g., `pods`, `services`, `secrets`, `ingresses`, etc.)
2. ✅ For each resource, choose:
   - 👁️ Read-only → `get`, `list`, `watch`
   - ✍️ Read-write → All verbs (`create`, `update`, `delete`, etc.)
   - 🎛️ Custom → Enter exactly the verbs you want

> 📌 Great for scenarios where you want **fine-grained RBAC control** — e.g., give read access to `secrets`, but full access to `pods`.



## 🔐 Script 2: `create-rbac-namespace-admin.sh`

This script is for granting full **admin-level access** to a namespace.

### 🧰 Role Includes:

- 🔗 API Groups: `""`, `apps`, `extensions`, `*`
- 📦 Resources: `*` (everything)
- 🛠️ Verbs: `*` (create, get, list, patch, delete, etc.)

> ⚠️ This grants unrestricted power over all resources in the namespace.



## 📚 Supported Kubernetes Resources

When using the **custom** mode, you can select from the following:

| Resource | Description |
|----------|-------------|
| `pods` | Individual containers/workloads |
| `services` | Networking abstraction |
| `deployments` | Declarative way to manage Pods |
| `configmaps` | Key-value config data |
| `secrets` | Confidential key-values (base64) |
| `persistentvolumeclaims` | Persistent storage requests |
| `jobs` | One-time tasks |
| `cronjobs` | Scheduled jobs |
| `replicasets` | Maintain Pod stability |
| `ingresses` | HTTP routing to Services |
| `events` | Read Kubernetes events |
| `roles` / `rolebindings` | RBAC components |
| `networkpolicies` | Control Pod networking |
| `namespaces`, `nodes` | ⚠️ Require ClusterRole access |

> 🛑 Accessing `nodes`, `namespaces`, etc. requires using a **ClusterRole** instead of a Role.



## 📄 Example Output

After running the script, you’ll get a file like:

```bash
kubeconfig-<username>.yaml
````

Use it like this:

```bash
export KUBECONFIG=./kubeconfig-<username>.yaml
kubectl get pods
```

Or merge with your existing `~/.kube/config`.

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


## 🛠️ Requirements

* 🧠 Basic Kubernetes knowledge
* ✅ `kubectl` with cluster-admin privileges
* 🐧 Linux/MacOS with Bash (or WSL on Windows)
* ✅ Kubernetes v1.20+



## 🚀 Usage

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

Feel free to contribute with:

* ✳️ ClusterRole support
* 📦 Helm templates
* 🔁 GitOps integration (e.g., ArgoCD, Flux)

## 🛡️ Disclaimer

This directory is for **namespace-level RBAC**. If you plan to use **ClusterRole/ClusterRoleBinding**, make sure you fully understand the implications and risks of cluster-wide access.



> ## 📝 About the Author
> #### Crafted with care and ❤️ by [Ali Rahmati](https://github.com/alirahmti). 👨‍💻
> If this repo saved you time or solved a problem, a ⭐ means everything in the DevOps world. 🧠💾
> Your star ⭐ is like a high five from the terminal — thanks for the support! 🙌🐧
