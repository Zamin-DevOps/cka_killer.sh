#!/bin/bash
# DESC: Scale down StatefulSet to 1 replica
# NODE: cka3962

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-h800"

print_header "Q3 | Scale down StatefulSet"

print_section "Task"
print_task "Scale StatefulSet o3db in Namespace project-h800 down to 1 replica"
echo ""

print_section "Environment Setup"
echo -e "  Creating Namespace ${CYAN}$NS${RESET} and StatefulSet ${CYAN}o3db${RESET}..."
echo ""

kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS" &>/dev/null

cat <<'EOF' | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: o3db
  namespace: project-h800
spec:
  serviceName: o3db
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

print_success "StatefulSet o3db created with 2 replicas in ns $NS"
echo ""
echo -e "  Current state:"
kubectl -n "$NS" get sts o3db 2>/dev/null || echo "  (StatefulSet being created...)"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Confirm it's a StatefulSet:${RESET}"
print_cmd "k -n $NS get pod | grep o3db"
print_cmd "k -n $NS get deploy,ds,sts | grep o3db"
echo ""

echo -e "${BOLD}Step 2 - Scale it down:${RESET}"
print_cmd "k -n $NS scale sts o3db --replicas 1"
echo ""

echo -e "${BOLD}Step 3 - Verify:${RESET}"
print_cmd "k -n $NS get sts o3db"
print_cmd "k -n $NS get pod | grep o3db"
echo ""

print_section "Expected Result"
echo "  NAME   READY   AGE"
echo "  o3db   1/1     Xs"
echo ""
print_hint "StatefulSets scale down from the highest index (o3db-1 is removed first)"
divider
