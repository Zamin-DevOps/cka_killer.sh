#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "5 — Kubectl Sorting" \
"Solve on: ssh cka5248

Tasks:
  a) Write a kubectl command that lists ALL pods in ALL namespaces
     sorted by their creation timestamp (oldest first).
     Save the command to: /opt/course/5/sort-pods.sh

  b) List all pods sorted by namespace, then by name.
     Save the command to: /opt/course/5/sort-pods-name.sh

  c) Find the pod that was created MOST RECENTLY across all namespaces.
     Write just the pod name to: /opt/course/5/newest-pod.txt"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/5

# Create pods with slight delay so timestamps differ
for ns in sort-ns-a sort-ns-b; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
done

kubectl run old-pod   --image=nginx:1-alpine -n sort-ns-a --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
sleep 2
kubectl run mid-pod   --image=nginx:1-alpine -n sort-ns-b --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
sleep 2
kubectl run new-pod   --image=nginx:1-alpine -n sort-ns-a --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

info "Created pods: old-pod(sort-ns-a), mid-pod(sort-ns-b), new-pod(sort-ns-a)"
info "Each created ~2s apart so timestamps are different"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  --sort-by=<jsonpath>  →  sort kubectl output by any field"
echo "  .metadata.creationTimestamp  →  when the object was created"
echo "  .metadata.namespace          →  namespace name"
echo "  .metadata.name               →  object name"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Part A — Sort all pods by creationTimestamp:${NC}"
cmd "kubectl get pods -A --sort-by=.metadata.creationTimestamp"
cmd "# Save the command:"
cmd "echo 'kubectl get pods -A --sort-by=.metadata.creationTimestamp' > /opt/course/5/sort-pods.sh"

echo ""
echo -e "${BOLD}Part B — Sort by namespace then name:${NC}"
cmd "kubectl get pods -A --sort-by=.metadata.namespace"
tip "kubectl can only sort by one field natively — for multi-field sort pipe to sort:"
cmd "kubectl get pods -A --no-headers | sort -k1,1 -k2,2"
cmd "echo \"kubectl get pods -A --no-headers | sort -k1,1 -k2,2\" > /opt/course/5/sort-pods-name.sh"

echo ""
echo -e "${BOLD}Part C — Find newest pod (last in timestamp sort = newest):${NC}"
cmd "kubectl get pods -A --sort-by=.metadata.creationTimestamp --no-headers | tail -1"
cmd "# Save just the pod name (column 2):"
cmd "kubectl get pods -A --sort-by=.metadata.creationTimestamp --no-headers | tail -1 | awk '{print \$2}' > /opt/course/5/newest-pod.txt"
cmd "cat /opt/course/5/newest-pod.txt"

separator
section "Verify"
cmd "sh /opt/course/5/sort-pods.sh"
cmd "cat /opt/course/5/newest-pod.txt"

expected "sort-pods.sh    → lists all pods oldest first
newest-pod.txt  → new-pod"
