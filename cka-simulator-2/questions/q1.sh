#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "1 — DNS / FQDN / Headless Service" \
"Solve on: ssh cka6016

The Deployment 'controller' in Namespace 'lima-control' communicates
with cluster-internal endpoints via DNS FQDNs.

Update the ConfigMap used by the Deployment with correct FQDN values:

  DNS_1: Service 'kubernetes' in Namespace 'default'
  DNS_2: Headless Service 'department' in Namespace 'lima-workload'
  DNS_3: Pod 'section100' in Namespace 'lima-workload'
          (must work even if Pod IP changes)
  DNS_4: A Pod with IP 1.2.3.4 in Namespace 'kube-system'

Ensure the Deployment works with the updated values."

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."

kubectl create namespace lima-control   --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
kubectl create namespace lima-workload  --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# Headless Service 'department'
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: department
  namespace: lima-workload
spec:
  clusterIP: None
  selector:
    name: department
  ports:
  - port: 80
EOF

# Service 'section' (for named pod DNS)
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: section
  namespace: lima-workload
spec:
  clusterIP: None
  selector:
    name: section
  ports:
  - port: 80
EOF

# Pod section100 with hostname + subdomain
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: section100
  namespace: lima-workload
  labels:
    name: section
spec:
  hostname: section100
  subdomain: section
  containers:
  - name: pod
    image: nginx:1-alpine
EOF

# Department pods (behind headless service)
for i in 1 2; do
kubectl apply -f - 2>/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: department-pod-$i
  namespace: lima-workload
  labels:
    name: department
spec:
  containers:
  - name: pod
    image: nginx:1-alpine
EOF
done

# ConfigMap with WRONG values (student must fix)
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: control-config
  namespace: lima-control
data:
  DNS_1: "FIXME"
  DNS_2: "FIXME"
  DNS_3: "FIXME"
  DNS_4: "FIXME"
EOF

# Controller Deployment that reads ConfigMap and does nslookup
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: controller
  namespace: lima-control
spec:
  replicas: 1
  selector:
    matchLabels:
      app: controller
  template:
    metadata:
      labels:
        app: controller
    spec:
      containers:
      - name: controller
        image: busybox:1
        command:
        - sh
        - -c
        - |
          while true; do
            nslookup $DNS_1 && \
            nslookup $DNS_2 && \
            nslookup $DNS_3 && \
            nslookup $DNS_4
            sleep 60
          done
        envFrom:
        - configMapRef:
            name: control-config
EOF

info "Environment ready!"
info "Namespace lima-control  → Deployment 'controller' + ConfigMap 'control-config'"
info "Namespace lima-workload → Headless svc 'department', svc 'section', pod 'section100'"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "DNS FQDN Formula — Yaad karo!"
echo "  Service:      SERVICE.NAMESPACE.svc.cluster.local"
echo "  Headless Svc: SERVICE.NAMESPACE.svc.cluster.local  (same! returns Pod IPs)"
echo "  Named Pod:    POD_HOSTNAME.SUBDOMAIN.NAMESPACE.svc.cluster.local"
echo "  Pod by IP:    1-2-3-4.NAMESPACE.pod.cluster.local  (dots → dashes)"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Exec into controller pod to test DNS:${NC}"
cmd "kubectl -n lima-control get pod"
cmd "kubectl -n lima-control exec -it <pod-name> -- sh"
cmd "  # Inside pod:"
cmd "  nslookup kubernetes.default.svc.cluster.local"
cmd "  nslookup department.lima-workload.svc.cluster.local"
cmd "  nslookup section100.section.lima-workload.svc.cluster.local"
cmd "  nslookup 1-2-3-4.kube-system.pod.cluster.local"

echo ""
echo -e "${BOLD}Step 2 — Edit the ConfigMap with correct values:${NC}"
cmd "kubectl -n lima-control edit cm control-config"
cat <<'YAML'

  # Correct values:
  data:
    DNS_1: kubernetes.default.svc.cluster.local
    DNS_2: department.lima-workload.svc.cluster.local
    DNS_3: section100.section.lima-workload.svc.cluster.local
    DNS_4: 1-2-3-4.kube-system.pod.cluster.local
YAML

echo ""
echo -e "${BOLD}Step 3 — Restart Deployment to pick up new ConfigMap:${NC}"
cmd "kubectl -n lima-control rollout restart deploy controller"
cmd "kubectl -n lima-control logs -f <new-pod-name>"

separator
expected "Logs should show all 4 nslookup commands succeeding without NXDOMAIN errors."
