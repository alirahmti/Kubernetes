#!/bin/bash
set -e

# ✍️ Author Info
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Kubernetes RBAC Custom User Generator"
echo "🧑‍💻 Crafted with ❤️  by Ali Rahmati  →  https://github.com/alirahmti"
echo "📅 Date: $(date '+%Y-%m-%d')"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""


# 🎯 Get inputs
read -p "👤 Enter username (e.g., ali): " USERNAME
read -p "📦 Enter namespace (e.g., devops): " NAMESPACE
read -p "🔗 Enter cluster endpoint (e.g., https://apisrv.example.com:8443): " CLUSTER_ENDPOINT

# 🧩 Access level selector
echo ""
echo "🔐✨ Let's define access for the user: 🧑 '${USERNAME}' in namespace: 📦 '${NAMESPACE}'"
echo ""
echo "👇 Please choose one of the following access levels:"
echo "──────────────────────────────────────────────────────────"
echo "  1) read-only    →  View-only access to basic resources"
echo "  2) read-write   →  Create / Update / Delete workloads"
echo "  3) admin        →  Full access to all namespace resources"
echo "  4) custom       →  Manually select resources and verbs"
echo "──────────────────────────────────────────────────────────"
echo ""


while true; do
  read -p "🎯 Select access level (type 1-4): " ACCESS_CHOICE
  case $ACCESS_CHOICE in
    1) ACCESS_LEVEL="read-only" && break ;;
    2) ACCESS_LEVEL="read-write" && break ;;
    3) ACCESS_LEVEL="admin" && break ;;
    4) ACCESS_LEVEL="custom" && break ;;
    *) echo "⚠️ Invalid option. Please enter a number between 1 and 4." ;;
  esac
done

echo ""
echo "✅ You selected access level: 🎯 '${ACCESS_LEVEL}' 🔐"

# 🛠️ Create namespace if it doesn't exist
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# 🛠️ Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $USERNAME
  namespace: $NAMESPACE
EOF

# 📦 Start building Role
ROLE_FILE=$(mktemp)
echo "apiVersion: rbac.authorization.k8s.io/v1" > "$ROLE_FILE"
echo "kind: Role" >> "$ROLE_FILE"
echo "metadata:" >> "$ROLE_FILE"
echo "  name: ${USERNAME}-role" >> "$ROLE_FILE"
echo "  namespace: $NAMESPACE" >> "$ROLE_FILE"
echo "rules:" >> "$ROLE_FILE"

if [[ "$ACCESS_LEVEL" == "custom" ]]; then
  echo ""
  echo "📚 Available Kubernetes Resources:"
  RES_NAMES=("pods" "services" "deployments" "configmaps" "secrets" "persistentvolumeclaims" "jobs" "cronjobs" "replicasets" "ingresses" "events" "roles" "rolebindings" "networkpolicies")
  i=1
  for r in "${RES_NAMES[@]}"; do
    printf "  %2d) 📦 %s\n" "$i" "$r"
    ((i++))
  done

  echo ""
  read -p "➡️  Enter comma-separated numbers of desired resources (e.g., 1,3,8): " SELECTED_RESOURCES
  IFS=',' read -ra INDICES <<< "$SELECTED_RESOURCES"

  for index in "${INDICES[@]}"; do
    RESOURCE="${RES_NAMES[$((index-1))]}"
    [[ -z "$RESOURCE" ]] && continue

    echo ""
    echo "🔹 Resource: 📦 $RESOURCE"
    echo "   1) 👁️  read-only (get, list, watch)"
    echo "   2) ✍️  read-write (get, list, watch, create, update, delete, patch)"
    echo "   3) 🎛️  custom (enter your own verbs)"
    read -p "⚙️  Select access type (1-3): " VERB_LEVEL

    case "$VERB_LEVEL" in
      1) VERBS="get,list,watch" ;;
      2) VERBS="get,list,watch,create,update,delete,patch" ;;
      3) read -p "🧪 Enter verbs (comma-separated): " VERBS ;;
      *) VERBS="get,list" ;;
    esac

    case "$RESOURCE" in
      deployments|replicasets) GROUP="apps" ;;
      ingresses|networkpolicies) GROUP="networking.k8s.io" ;;
      jobs|cronjobs) GROUP="batch" ;;
      roles|rolebindings) GROUP="rbac.authorization.k8s.io" ;;
      *) GROUP="" ;;
    esac

    echo "- apiGroups: [\"$GROUP\"]" >> "$ROLE_FILE"
    echo "  resources: [\"$RESOURCE\"]" >> "$ROLE_FILE"
    echo "  verbs: [$(echo "$VERBS" | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')]" >> "$ROLE_FILE"
  done

else
  if [[ "$ACCESS_LEVEL" == "read-only" ]]; then
    cat <<EOF >> "$ROLE_FILE"
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
EOF
  elif [[ "$ACCESS_LEVEL" == "read-write" ]]; then
    cat <<EOF >> "$ROLE_FILE"
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
EOF
  elif [[ "$ACCESS_LEVEL" == "admin" ]]; then
    cat <<EOF >> "$ROLE_FILE"
- apiGroups: ["", "apps", "extensions", "*"]
  resources: ["*"]
  verbs: ["*"]
EOF
  fi
fi

# 🚀 Apply Role
kubectl apply -f "$ROLE_FILE"
rm -f "$ROLE_FILE"

# 🔗 Create RoleBinding
kubectl apply -f - <<EOF
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

# 🔐 Create Secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${USERNAME}-token
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: "$USERNAME"
type: kubernetes.io/service-account-token
EOF

echo ""
echo "⏳ Waiting for token to become available..."
sleep 5

# 🧾 Generate kubeconfig
TOKEN=$(kubectl get secret ${USERNAME}-token -n "$NAMESPACE" -o jsonpath="{.data.token}" | base64 --decode)
CA_CRT=$(kubectl get secret ${USERNAME}-token -n "$NAMESPACE" -o jsonpath="{.data['ca\\.crt']}" | base64 --decode | base64 -w 0)

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

echo ""
echo "✅🔐 Kubeconfig for user '${USERNAME}' with 🎯 '${ACCESS_LEVEL}' access to namespace '${NAMESPACE}' has been successfully generated! 📄🚀"
echo "📦 File saved as: kubeconfig-${USERNAME}.yaml"
