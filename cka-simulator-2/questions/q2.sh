#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "2 — Create a Static Pod and Service" \
"Solve on: ssh cka2560

Tasks:
  a) Create a Static Pod named 'my-static-pod' in Namespace 'default'
     on the controlplane node.
     - image: nginx:1-alpine
     - resource requests: cpu=10m, memory=20Mi

  b) Create a NodePort Service named 'static-pod-service'
     that exposes the static Pod on port 80.

Verify: Service has one Endpoint and pod is accessible via
        curl <NODE-IP>:<NODE-PORT>"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
info "No pre-setup needed — you create everything from scratch."
info "Static Pod path on controlplane: /etc/kubernetes/manifests/"

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
info "Controlplane internal IP: ${NODE_IP:-run: kubectl get node -owide}"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Static Pod = YAML file placed in /etc/kubernetes/manifests/"
echo "  kubelet watches that folder and auto-creates the Pod."
echo "  Static Pod name gets node-name as suffix: my-static-pod-cka2560"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — SSH to controlplane and become root:${NC}"
cmd "sudo -i"
cmd "cd /etc/kubernetes/manifests/"

echo ""
echo -e "${BOLD}Step 2 — Generate static pod YAML and save to manifests dir:${NC}"
cmd "kubectl run my-static-pod --image=nginx:1-alpine --dry-run=client -o yaml > my-static-pod.yaml"
cmd "# Then edit to add resource requests:"
cmd "vim my-static-pod.yaml"
cat <<'YAML'

  # Add this under containers[0]:
  resources:
    requests:
      cpu: 10m
      memory: 20Mi
YAML

echo ""
echo -e "${BOLD}Step 3 — Verify the static pod is Running:${NC}"
cmd "kubectl get pod -A | grep my-static"
cmd "# Should show: default  my-static-pod-cka2560  1/1  Running"

echo ""
echo -e "${BOLD}Step 4 — Expose the static pod with NodePort Service:${NC}"
cmd "kubectl expose pod my-static-pod-cka2560 --name static-pod-service --type=NodePort --port 80"

echo ""
echo -e "${BOLD}Step 5 — Verify Service has an Endpoint:${NC}"
cmd "kubectl get svc static-pod-service"
cmd "kubectl get endpointslice -l kubernetes.io/service-name=static-pod-service"

echo ""
echo -e "${BOLD}Step 6 — Test access via NodePort:${NC}"
cmd "kubectl get svc static-pod-service"
cmd "# Note the NodePort (30000-32767 range)"
cmd "curl <NODE-IP>:<NODE-PORT>"

separator
expected "Static Pod:      my-static-pod-cka2560   1/1 Running
Service:         static-pod-service NodePort 80:<port>/TCP
Endpoint:        <pod-ip>:80
curl response:   Welcome to nginx!"
