#!/bin/bash
# DESC: Find BestEffort Pods (first to be terminated)
# NODE: cka2556

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-c13"
OUT_DIR="/opt/course/4"
OUT_FILE="$OUT_DIR/pods-terminated-first.txt"

print_header "Q4 | Find Pods First to be Terminated"

print_section "Task"
print_task "Find Pods in Namespace $NS that would be terminated FIRST when node runs out of resources"
print_task "Write those Pod names to: $OUT_FILE"
echo ""
print_note "Pods with NO resource requests = BestEffort QoS = terminated first"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"

kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS" &>/dev/null

# Pods WITH resource requests (Burstable QoS - safe)
for app in c13-2x3-api c13-2x3-web c13-3cc-data c13-3cc-web; do
  cat <<EOF | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app
  namespace: $NS
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $app
  template:
    metadata:
      labels:
        app: $app
    spec:
      containers:
      - name: app
        image: nginx:alpine
        resources:
          requests:
            cpu: 50m
            memory: 10Mi
EOF
done

# Pods WITHOUT resource requests (BestEffort QoS - terminated first!)
cat <<'EOF' | kubectl apply -f - &>/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: c13-3cc-runner-heavy
  namespace: project-c13
spec:
  replicas: 3
  selector:
    matchLabels:
      app: c13-3cc-runner-heavy
  template:
    metadata:
      labels:
        app: c13-3cc-runner-heavy
    spec:
      containers:
      - name: app
        image: nginx:alpine
        # No resource requests = BestEffort = terminated first
EOF

print_success "Deployments created in namespace $NS"
echo ""
echo -e "  ${YELLOW}Waiting a moment for pods to start...${RESET}"
sleep 3
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Inspect resource requests of all Pods:${RESET}"
print_cmd "k -n $NS describe pod | grep -A 3 -E 'Requests|^Name:'"
echo ""

echo -e "${BOLD}Step 2 - Or use jsonpath to list pods + their resources:${RESET}"
print_cmd "k -n $NS get pod -o jsonpath=\"{range .items[*]} {.metadata.name}{.spec.containers[*].resources}{'\\\n'}\""
echo ""

echo -e "${BOLD}Step 3 - Or check QoS class directly:${RESET}"
print_cmd "k get pods -n $NS -o jsonpath=\"{range .items[*]}{.metadata.name} {.status.qosClass}{'\\\n'}\""
echo ""

echo -e "${BOLD}Step 4 - Write BestEffort Pod names to file:${RESET}"
print_cmd "k get pods -n $NS -o jsonpath=\"{range .items[*]}{.metadata.name} {.status.qosClass}{'\\\n'}\" | grep BestEffort | awk '{print \$1}' > $OUT_FILE"
echo ""

print_section "Key Concept - QoS Classes"
echo ""
echo -e "  ${RED}BestEffort${RESET}   → No requests/limits set     → Terminated FIRST  ⚠️"
echo -e "  ${YELLOW}Burstable${RESET}    → Requests set (< limits)    → Terminated second"
echo -e "  ${GREEN}Guaranteed${RESET}   → Requests == Limits         → Terminated last  ✅"
echo ""

print_hint "The deployment 'c13-3cc-runner-heavy' has no resource requests — those pods are BestEffort"
print_hint "After running the commands, check: cat $OUT_FILE"
divider
