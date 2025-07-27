#!/bin/bash

set -e

# 🎯 Get inputs
read -p "Enter username (e.g., ali): " USERNAME
read -p "Enter namespace (e.g., devops): " NAMESPACE
read -p "Enter cluster endpoint (e.g., https://apisrv.example.com:8443): " CLUSTER_ENDPOINT

echo "Select access level:"
select ACCESS_LEVEL in "read-only" "read-write" "admin"; do
  if [[ -n "$ACCESS_LEVEL" ]]; then
    break
  fi
done

# 🛠️ Create namespace if it doesn't exist
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# 🛠️ ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
EOF

# 📚 Define Role based on access level
ROLE_FILE=$(mktemp)
case $ACCESS_LEVEL in
  "read-only")
    cat <<EOF > $ROLE_FILE
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${USERNAME}-role
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
EOF
    ;;
  "read-write")
    cat <<EOF > $ROLE_FILE
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${USERNAME}-role
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "delete", "update", "patch"]
EOF
    ;;
  "admin")
    cat <<EOF > $ROLE_FILE
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${USERNAME}-role
  namespace: $NAMESPACE
rules:
- apiGroups: ["", "apps", "extensions", "*"]
  resources: ["*"]
  verbs: ["*"]
EOF
    ;;
esac

kubectl apply -f "$ROLE_FILE"
rm -f "$ROLE_FILE"

# 🔗 RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USERNAME}-binding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $USERNAME
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: ${USERNAME}-role
  apiGroup: rbac.authorization.k8s.io
EOF

# 🔐 Secret Token
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ${USERNAME}-token
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$USERNAME"
type: kubernetes.io/service-account-token
EOF

echo "⏳ Waiting for token to become available..."
sleep 5

# 🧠 Extract token and CA
TOKEN=$(kubectl get secret ${USERNAME}-token -n $NAMESPACE -o jsonpath="{.data.token}" | base64 --decode)
CA_CRT=$(kubectl get secret ${USERNAME}-token -n $NAMESPACE -o jsonpath="{.data['ca\.crt']}" | base64 --decode | base64 -w 0)

# 📄 Kubeconfig
cat <<EOF > kubeconfig-${USERNAME}.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: ${CA_CRT}
    server: ${CLUSTER_ENDPOINT}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: ${USERNAME}
    namespace: ${NAMESPACE}
  name: ${USERNAME}-context
current-context: ${USERNAME}-context
users:
- name: ${USERNAME}
  user:
    token: ${TOKEN}
EOF

echo "✅🔐 Kubeconfig for user '${USERNAME}' with 🎯 '${ACCESS_LEVEL}' access to namespace '${NAMESPACE}' has been successfully generated! 📄🚀"
echo "📦 File: kubeconfig-${USERNAME}.yaml"
