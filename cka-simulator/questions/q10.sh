#!/bin/bash
# DESC: RBAC - ServiceAccount, Role, RoleBinding for Secrets+ConfigMaps
# NODE: cka3962

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-hamster"

print_header "Q10 | RBAC - ServiceAccount Role RoleBinding"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create ServiceAccount ${CYAN}processor${RESET} in ns ${CYAN}project-hamster${RESET}"
echo -e "  ${BOLD}2.${RESET} Create Role ${CYAN}processor${RESET}: allow create Secrets + ConfigMaps only"
echo -e "  ${BOLD}3.${RESET} Create RoleBinding ${CYAN}processor${RESET}: bind Role to ServiceAccount"
echo ""

print_section "Environment Setup"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"
print_success "Namespace $NS ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Create ServiceAccount:${RESET}"
print_cmd "k -n $NS create sa processor"
echo ""

echo -e "${BOLD}Step 2 - Create Role (create only for secrets + configmaps):${RESET}"
print_cmd "k -n $NS create role processor --verb=create --resource=secret --resource=configmap"
echo ""
echo -e "  ${CYAN}Generated YAML:${RESET}"
cat <<'EOF'
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: processor
    namespace: project-hamster
  rules:
  - apiGroups: [""]
    resources: ["secrets", "configmaps"]
    verbs: ["create"]
EOF
echo ""

echo -e "${BOLD}Step 3 - Create RoleBinding:${RESET}"
print_cmd "k -n $NS create rolebinding processor --role processor --serviceaccount $NS:processor"
echo ""

echo -e "${BOLD}Step 4 - Verify permissions:${RESET}"
print_cmd "k -n $NS auth can-i create secret     --as system:serviceaccount:$NS:processor"
print_cmd "k -n $NS auth can-i create configmap  --as system:serviceaccount:$NS:processor"
print_cmd "k -n $NS auth can-i create pod        --as system:serviceaccount:$NS:processor"
print_cmd "k -n $NS auth can-i delete secret     --as system:serviceaccount:$NS:processor"
print_cmd "k -n $NS auth can-i get configmap     --as system:serviceaccount:$NS:processor"
echo ""

print_section "Expected Results"
echo -e "  create secret    → ${GREEN}yes${RESET}"
echo -e "  create configmap → ${GREEN}yes${RESET}"
echo -e "  create pod       → ${RED}no${RESET}"
echo -e "  delete secret    → ${RED}no${RESET}"
echo -e "  get configmap    → ${RED}no${RESET}"
echo ""

print_section "RBAC Cheat Sheet"
echo -e "  ${BOLD}Role + RoleBinding${RESET}          → single namespace scope"
echo -e "  ${BOLD}ClusterRole + ClusterRoleBinding${RESET} → cluster-wide scope"
echo -e "  ${BOLD}ClusterRole + RoleBinding${RESET}    → available cluster-wide, applied in one ns"
echo -e "  ${RED}Role + ClusterRoleBinding${RESET}    → NOT VALID"
echo ""

print_hint "Always test with 'k auth can-i' after creating RBAC resources"
divider
