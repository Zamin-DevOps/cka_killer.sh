#!/bin/bash
# DESC: Contact K8s API from inside Pod using ServiceAccount token
# NODE: cka9412

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-swan"
OUT_DIR="/opt/course/9"

print_header "Q9 | Contact K8s API from Inside Pod"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create Pod ${CYAN}api-contact${RESET} (image: nginx:1-alpine) using SA ${CYAN}secret-reader${RESET} in ns ${CYAN}project-swan${RESET}"
echo -e "  ${BOLD}2.${RESET} Exec into Pod and use curl to list all Secrets via K8s API"
echo -e "  ${BOLD}3.${RESET} Write result to ${CYAN}$OUT_DIR/result.json${RESET}"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"

kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"

# Create ServiceAccount
kubectl -n "$NS" get sa secret-reader &>/dev/null || \
  kubectl -n "$NS" create sa secret-reader

# Create ClusterRole + RoleBinding to read secrets
cat <<'EOF' | kubectl apply -f - &>/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-reader-binding
  namespace: project-swan
subjects:
- kind: ServiceAccount
  name: secret-reader
  namespace: project-swan
roleRef:
  kind: ClusterRole
  name: secret-reader-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Create a test secret
kubectl -n "$NS" get secret read-me &>/dev/null || \
  kubectl -n "$NS" create secret generic read-me --from-literal=token=supersecret123

print_success "ServiceAccount 'secret-reader', RoleBinding, and test Secret created in ns $NS"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Create the Pod yaml:${RESET}"
print_cmd "k run api-contact --image=nginx:1-alpine --dry-run=client -o yaml > 9.yaml"
print_cmd "vim 9.yaml"
echo ""
echo -e "  Add these fields:"
echo '    namespace: project-swan         # under metadata'
echo '    serviceAccountName: secret-reader  # under spec'
echo ""
print_cmd "k apply -f 9.yaml"
echo ""

echo -e "${BOLD}Step 2 - Verify SA permissions:${RESET}"
print_cmd "k auth can-i get secret --as system:serviceaccount:$NS:secret-reader -n $NS"
echo ""

echo -e "${BOLD}Step 3 - Exec into Pod and test API access:${RESET}"
print_cmd "k -n $NS exec api-contact -it -- sh"
echo ""
echo -e "  Inside the pod:"
echo '  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)'
echo '  CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
echo '  curl --cacert ${CACERT} https://kubernetes.default/api/v1/secrets -H "Authorization: Bearer ${TOKEN}"'
echo ""

echo -e "${BOLD}Step 4 - Save result to file:${RESET}"
echo '  # Option A - inside pod:'
echo '  curl --cacert ${CACERT} https://kubernetes.default/api/v1/namespaces/project-swan/secrets \'
echo '    -H "Authorization: Bearer ${TOKEN}" > /tmp/result.json'
echo '  exit'
echo ""
print_cmd "k -n $NS exec api-contact -- cat /tmp/result.json > $OUT_DIR/result.json"
echo ""

print_section "Verify"
print_cmd "cat $OUT_DIR/result.json | python3 -m json.tool | head -20"
echo ""

print_hint "ServiceAccount token is auto-mounted at /var/run/secrets/kubernetes.io/serviceaccount/"
print_hint "Use --cacert for proper TLS or -k to skip (insecure) for practice"
print_note "kubernetes.default resolves to the K8s API Service in the default namespace"
divider
