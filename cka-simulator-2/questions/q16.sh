#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "16 — Namespaces and Api Resources" \
"Solve on: ssh cka3200

Tasks:
  a) Write the names of ALL namespaced Kubernetes resources
     (like Pod, Secret, ConfigMap...) to:
     /opt/course/16/resources.txt

  b) Find the project-* Namespace with the HIGHEST number
     of Roles defined in it.
     Write its name and the Role count to:
     /opt/course/16/crowded-namespace.txt"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/16

# Create project-* namespaces with different number of roles
for ns in project-alpha project-beta project-gamma project-delta; do
  kubectl create namespace $ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
done

# project-alpha → 2 roles
for i in 1 2; do
  kubectl -n project-alpha create role role-$i --verb=get --resource=pods \
    --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
done

# project-beta → 5 roles (winner)
for i in 1 2 3 4 5; do
  kubectl -n project-beta create role role-$i --verb=get --resource=pods \
    --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
done

# project-gamma → 1 role
kubectl -n project-gamma create role role-1 --verb=get --resource=pods \
  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# project-delta → 3 roles
for i in 1 2 3; do
  kubectl -n project-delta create role role-$i --verb=get --resource=pods \
    --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
done

info "Created project-* namespaces with varying number of Roles:"
info "  project-alpha: 2 roles"
info "  project-beta:  5 roles  ← most"
info "  project-gamma: 1 role"
info "  project-delta: 3 roles"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  kubectl api-resources --namespaced=true  → only namespaced resources"
echo "  kubectl api-resources --namespaced=false → only cluster-scoped"
echo "  -o name → just print the resource type names"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Part A — Get all namespaced resources:${NC}"
cmd "kubectl api-resources --namespaced=true"
cmd "kubectl api-resources --namespaced=true -o name"
cmd "# Save to file:"
cmd "kubectl api-resources --namespaced=true -o name > /opt/course/16/resources.txt"
cmd "cat /opt/course/16/resources.txt"
cmd "wc -l /opt/course/16/resources.txt   # how many resources?"

echo ""
echo -e "${BOLD}Part B — Count Roles in each project-* namespace:${NC}"
cmd "kubectl get namespace | grep project-"
echo ""
cmd "# Count roles in each namespace:"
for ns in project-alpha project-beta project-gamma project-delta; do
  cmd "echo -n '$ns: '; kubectl -n $ns get role --no-headers 2>/dev/null | wc -l"
done

echo ""
tip "Or loop it automatically:"
cmd "for ns in \$(kubectl get ns -o name | grep project | cut -d/ -f2); do"
cmd "  count=\$(kubectl -n \$ns get role --no-headers 2>/dev/null | wc -l)"
cmd "  echo \"\$ns: \$count\""
cmd "done"

echo ""
echo -e "${BOLD}Write the winner to file:${NC}"
cmd "echo 'project-beta with 5 roles' > /opt/course/16/crowded-namespace.txt"
cmd "cat /opt/course/16/crowded-namespace.txt"

separator
expected "resources.txt:
  bindings
  configmaps
  endpoints
  pods
  secrets
  ... (30+ resources)

crowded-namespace.txt:
  project-beta with 5 roles"
