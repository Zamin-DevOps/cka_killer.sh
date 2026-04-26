#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "4 — Pod Ready if Service is Reachable" \
"Solve on: ssh cka5248

There is a Pod 'web-pod' in namespace 'ready-ns'.
It should only show as Ready when Service 'backend-svc'
in the same namespace is reachable on port 80.

Tasks:
  a) Add a readinessProbe to 'web-pod' that checks if
     backend-svc:80 is reachable using a TCP socket check.
     - initialDelaySeconds: 5
     - periodSeconds: 10

  b) Create the Service 'backend-svc' (ClusterIP, port 80)
     pointing to a backend Pod.

  c) Verify: web-pod becomes Ready only after backend-svc exists."

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
kubectl create namespace ready-ns --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# Web pod WITHOUT readinessProbe — student must add it
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  namespace: ready-ns
spec:
  containers:
  - name: web
    image: nginx:1-alpine
    ports:
    - containerPort: 80
EOF

# Backend pod (for the service to point to)
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  namespace: ready-ns
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: nginx:1-alpine
    ports:
    - containerPort: 80
EOF

info "Created: web-pod (no readinessProbe yet) and backend-pod in ready-ns"
info "Service 'backend-svc' does NOT exist yet — you create it"
kubectl -n ready-ns get pod 2>/dev/null

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  readinessProbe → tells K8s 'is this pod ready to receive traffic?'"
echo "  tcpSocket      → just checks if the port is open (no HTTP needed)"
echo "  If probe fails → pod stays in Ready=False, no traffic routed to it"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Edit web-pod to add readinessProbe:${NC}"
cmd "kubectl -n ready-ns edit pod web-pod"
cat <<'YAML'

  # Add under containers[0]:
  readinessProbe:
    tcpSocket:
      host: backend-svc
      port: 80
    initialDelaySeconds: 5
    periodSeconds: 10
YAML
tip "You cannot edit a running pod directly — delete and recreate, or use replace:"
cmd "kubectl -n ready-ns get pod web-pod -o yaml > web-pod.yaml"
cmd "# edit web-pod.yaml to add readinessProbe"
cmd "kubectl -n ready-ns replace --force -f web-pod.yaml"

echo ""
echo -e "${BOLD}Step 2 — Check web-pod is NOT Ready (backend-svc missing):${NC}"
cmd "kubectl -n ready-ns get pod web-pod"
cmd "# READY column should show: 0/1"

echo ""
echo -e "${BOLD}Step 3 — Create backend-svc:${NC}"
cmd "kubectl -n ready-ns expose pod backend-pod --name backend-svc --port 80"

echo ""
echo -e "${BOLD}Step 4 — Watch web-pod become Ready:${NC}"
cmd "kubectl -n ready-ns get pod web-pod -w"
cmd "# READY should change to: 1/1"

separator
expected "Before svc: web-pod  0/1  Running
After svc:  web-pod  1/1  Running"
