#!/bin/bash

set -e

read -p "Enter username (e.g., ali): " USERNAME
read -p "Enter namespace (e.g., devops): " NAMESPACE
read -p "Enter cluster endpoint (e.g., https://apisrv.example.com:8443): " CLUSTER_ENDPOINT

kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${USERNAME}-admin-role
  namespace: $NAMESPACE
rules:
- apiGroups: ["", "apps", "extensions", "*"]
  resources: ["*"]
  verbs: ["*"]
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USERNAME}-admin-binding
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: $USERNAME
  namespace: $NAMESPACE
roleRef:
  kind: Role
  name: ${USERNAME}-admin-role
  apiGroup: rbac.authorization.k8s.io
EOF

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

sleep 5

TOKEN=$(kubectl get secret ${USERNAME}-token -n $NAMESPACE -o jsonpath="{.data.token}" | base64 --decode)
CA_CRT=$(kubectl get secret ${USERNAME}-token -n $NAMESPACE -o jsonpath="{.data['ca\.crt']}" | base64 --decode | base64 -w 0)

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

echo "✅ Admin kubeconfig created: kubeconfig-${USERNAME}.yaml"
