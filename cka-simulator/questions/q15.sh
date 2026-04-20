#!/bin/bash
# DESC: NetworkPolicy - restrict backend Pod egress to specific ports
# NODE: cka7968

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-snake"

print_header "Q15 | NetworkPolicy"

print_section "Task"
echo -e "  Create NetworkPolicy ${CYAN}np-backend${RESET} in ns ${CYAN}$NS${RESET}:"
echo ""
echo -e "  Allow backend-* Pods to connect to:"
echo -e "    ${GREEN}✅${RESET} db1-* Pods on port ${CYAN}1111${RESET}"
echo -e "    ${GREEN}✅${RESET} db2-* Pods on port ${CYAN}2222${RESET}"
echo ""
echo -e "  Block everything else (e.g. vault-* on port 3333)"
echo ""

print_section "Environment Setup"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"

for app in backend db1 db2 vault; do
  kubectl -n "$NS" get pod "${app}-0" &>/dev/null && continue
  cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: ${app}-0
  namespace: $NS
  labels:
    app: $app
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 1111
    - containerPort: 2222
    - containerPort: 3333
EOF
done

print_success "Pods created: backend-0, db1-0, db2-0, vault-0 in ns $NS"
echo ""
echo -e "  Current Pod labels:"
kubectl -n "$NS" get pod -L app 2>/dev/null || echo "  (pods starting...)"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Check current connectivity (before policy):${RESET}"
print_cmd "k -n $NS get pod -o wide"
print_cmd "k -n $NS exec backend-0 -- curl -s <db1-ip>:1111"
print_cmd "k -n $NS exec backend-0 -- curl -s <vault-ip>:3333   # should work now"
echo ""

echo -e "${BOLD}Step 2 - Create the NetworkPolicy:${RESET}"
print_cmd "vim 15_np.yaml"
echo ""

cat <<'EOF'
  # 15_np.yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: np-backend
    namespace: project-snake
  spec:
    podSelector:
      matchLabels:
        app: backend
    policyTypes:
      - Egress
    egress:
      -                             # Rule 1: allow to db1 on port 1111
        to:
        - podSelector:
            matchLabels:
              app: db1
        ports:
        - protocol: TCP
          port: 1111
      -                             # Rule 2: allow to db2 on port 2222
        to:
        - podSelector:
            matchLabels:
              app: db2
        ports:
        - protocol: TCP
          port: 2222
EOF
echo ""

print_cmd "k apply -f 15_np.yaml"
echo ""

echo -e "${BOLD}Step 3 - Test connectivity (after policy):${RESET}"
print_cmd "k -n $NS exec backend-0 -- curl -s <db1-ip>:1111    # ✅ should work"
print_cmd "k -n $NS exec backend-0 -- curl -s <db2-ip>:2222    # ✅ should work"
print_cmd "k -n $NS exec backend-0 -- curl -s <vault-ip>:3333  # ❌ should be blocked"
echo ""

print_section "Key Concept - AND vs OR in NetworkPolicy"
echo ""
echo -e "  ${GREEN}Correct - Two separate rules (conditions linked by AND within each):${RESET}"
echo "    egress:"
echo "      -                     ← rule 1"
echo "        to: [app: db1]      ← condition A"
echo "        ports: [1111]       ← condition B"
echo "                             → (to db1) AND (port 1111)"
echo "      -                     ← rule 2"
echo "        to: [app: db2]      ← condition A"
echo "        ports: [2222]       ← condition B"
echo "                             → (to db2) AND (port 2222)"
echo ""
echo -e "  ${RED}Wrong - One rule with combined conditions (OR between to/ports):${RESET}"
echo "    egress:"
echo "      - to: [db1, db2]      ← OR between pods"
echo "        ports: [1111, 2222] ← OR between ports"
echo "                             → allows db1:2222, db2:1111 (WRONG!)"
echo ""

print_hint "Test the WRONG case: db1 on port 2222 should be blocked with correct policy"
divider
