#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "9 — Kill Scheduler / Manual Scheduling" \
"Solve on: ssh cka5248

Tasks:
  a) Temporarily stop the kube-scheduler
     (in a way it can be started again)

  b) Create a Pod named 'manual-schedule' of image httpd:2-alpine
     Confirm it is created but NOT scheduled (no node assigned)

  c) Manually schedule that Pod on node 'cka5248'
     Make sure it is Running

  d) Start the kube-scheduler again
     Create a second Pod 'manual-schedule2' of image httpd:2-alpine
     Confirm it gets scheduled on 'cka5248-node1' automatically"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
info "No pre-setup needed."
info "Nodes in this cluster:"
kubectl get nodes 2>/dev/null

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  kube-scheduler is a Static Pod → YAML in /etc/kubernetes/manifests/"
echo "  Move the YAML out → scheduler stops"
echo "  Move it back → scheduler restarts"
echo ""
echo "  Manual scheduling trick → set spec.nodeName directly in Pod YAML"
echo "  When nodeName is set, scheduler is bypassed completely"
echo "  Even controlplane taints don't matter when you set nodeName manually"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Stop the scheduler (move yaml out of manifests):${NC}"
cmd "sudo -i"
cmd "cd /etc/kubernetes/manifests/"
cmd "mv kube-scheduler.yaml /etc/kubernetes/"
cmd "# Wait for scheduler pod to disappear:"
cmd "watch crictl ps"
cmd "kubectl -n kube-system get pod | grep scheduler"
cmd "# Should show nothing"

echo ""
echo -e "${BOLD}Step 2 — Create a pod and confirm it is Pending (no node):${NC}"
cmd "kubectl run manual-schedule --image=httpd:2-alpine"
cmd "kubectl get pod manual-schedule -o wide"
cmd "# NODE column should show: <none>"

echo ""
echo -e "${BOLD}Step 3 — Manually schedule the Pod (add nodeName):${NC}"
cmd "kubectl get pod manual-schedule -o yaml > /tmp/manual.yaml"
cmd "vim /tmp/manual.yaml"
cat <<'CONTENT'

  # Add this line under spec: (same level as containers:)
  spec:
    nodeName: cka5248    # ← ADD THIS — controlplane node name
    containers:
    ...
CONTENT
cmd "# Apply with replace --force (delete + recreate):"
cmd "kubectl replace --force -f /tmp/manual.yaml"
cmd "kubectl get pod manual-schedule -o wide"
cmd "# Should now show NODE: cka5248 and STATUS: Running"

echo ""
echo -e "${BOLD}Step 4 — Restart the scheduler:${NC}"
cmd "cd /etc/kubernetes/manifests/"
cmd "mv /etc/kubernetes/kube-scheduler.yaml ."
cmd "watch crictl ps"
cmd "kubectl -n kube-system get pod | grep scheduler"
cmd "# Should come back as Running"

echo ""
echo -e "${BOLD}Step 5 — Create second pod and verify auto-scheduling:${NC}"
cmd "kubectl run manual-schedule2 --image=httpd:2-alpine"
cmd "kubectl get pod -o wide | grep schedule"
cmd "# manual-schedule  → cka5248 (controlplane, manually placed)"
cmd "# manual-schedule2 → cka5248-node1 (worker, auto-scheduled)"

separator
expected "manual-schedule   Running  cka5248
manual-schedule2  Running  cka5248-node1"
