#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "12 — Schedule Pod on Controlplane Nodes" \
"Solve on: ssh cka5248

Tasks:
  Create a Pod named 'pod1' in Namespace 'default':
  - image: httpd:2-alpine
  - container name: pod1-container
  - Must be scheduled ONLY on controlplane nodes
  - Do NOT add new labels to any nodes"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
info "Checking nodes and taints..."
kubectl get nodes 2>/dev/null
echo ""
kubectl describe nodes 2>/dev/null | grep -E "Name:|Taints:" | paste - -

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Controlplane node has this taint:"
echo "    node-role.kubernetes.io/control-plane:NoSchedule"
echo ""
echo "  To schedule ON controlplane you need BOTH:"
echo "    1. toleration  → 'I can tolerate the taint (allow me on controlplane)'"
echo "    2. nodeSelector → 'Schedule me ONLY on controlplane (not workers too)'"
echo ""
echo "  Without nodeSelector → Pod could go to worker nodes too!"
echo "  Without toleration   → Pod gets rejected from controlplane!"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Check controlplane node labels:${NC}"
cmd "kubectl get node --show-labels | grep control-plane"
cmd "# Look for label: node-role.kubernetes.io/control-plane"
cmd "kubectl describe node <controlplane-name> | grep Taints"

echo ""
echo -e "${BOLD}Step 2 — Generate Pod YAML:${NC}"
cmd "kubectl run pod1 --image=httpd:2-alpine --dry-run=client -o yaml > /tmp/pod1.yaml"
cmd "vim /tmp/pod1.yaml"
cat <<'YAML'

# Complete pod1.yaml:
apiVersion: v1
kind: Pod
metadata:
  name: pod1
  namespace: default
  labels:
    run: pod1
spec:
  containers:
  - image: httpd:2-alpine
    name: pod1-container        # ← question asked for this specific name
    resources: {}

  tolerations:                                  # ← needed to GET ON controlplane
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane  # ← exact taint key

  nodeSelector:                                 # ← needed to STAY ON controlplane
    node-role.kubernetes.io/control-plane: ""   # ← "" means key just needs to exist

  dnsPolicy: ClusterFirst
  restartPolicy: Always
YAML

echo ""
echo -e "${BOLD}Step 3 — Apply and verify:${NC}"
cmd "kubectl apply -f /tmp/pod1.yaml"
cmd "kubectl get pod pod1 -o wide"
cmd "# NODE column should show controlplane node name"

separator
section "Alternative — using nodeAffinity instead of nodeSelector"
cat <<'YAML'
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role.kubernetes.io/control-plane
            operator: Exists
YAML
echo "  Note: still need the toleration even with nodeAffinity!"

separator
expected "pod1   1/1   Running   <controlplane-node-name>"
