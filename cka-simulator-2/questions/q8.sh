#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "8 — Get Controlplane Information" \
"Solve on: ssh cka8448

Check how the following components are started on the controlplane:
  kubelet, kube-apiserver, kube-scheduler,
  kube-controller-manager, etcd

Also find the DNS application name and how it is started.

Write findings to: /opt/course/8/controlplane-components.txt

Format:
  kubelet: [TYPE]
  kube-apiserver: [TYPE]
  kube-scheduler: [TYPE]
  kube-controller-manager: [TYPE]
  etcd: [TYPE]
  dns: [TYPE] [NAME]

Choices for TYPE: not-installed | process | static-pod | pod"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/8
info "No pre-setup needed — investigate the running cluster"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept — Component Types"
echo "  process     → runs as systemd service (check: systemctl status <name>)"
echo "  static-pod  → YAML in /etc/kubernetes/manifests/ (kubelet manages it)"
echo "  pod         → normal K8s pod managed by Deployment/DaemonSet"
echo "  not-installed → binary not found anywhere"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Check kubelet (always a systemd process):${NC}"
cmd "service kubelet status"
cmd "find /usr/lib/systemd | grep kubelet"
cmd "# If found in systemd → TYPE = process"

echo ""
echo -e "${BOLD}Step 2 — Check static pods (apiserver, scheduler, controller, etcd):${NC}"
cmd "find /etc/kubernetes/manifests/"
cmd "# If YAML files exist for them → TYPE = static-pod"
cmd "ls /etc/kubernetes/manifests/"

echo ""
echo -e "${BOLD}Step 3 — Check all kube-system pods:${NC}"
cmd "kubectl -n kube-system get pod -o wide"
cmd "# Look for coredns, weave-net etc."

echo ""
echo -e "${BOLD}Step 4 — Find DNS application:${NC}"
cmd "kubectl -n kube-system get pod | grep -i dns"
cmd "kubectl -n kube-system get deploy | grep -i dns"
cmd "kubectl -n kube-system get ds"
cmd "# coredns is usually a Deployment → TYPE = pod"

echo ""
echo -e "${BOLD}Step 5 — Find Service CIDR (bonus — needed for Q14):${NC}"
cmd "cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range"

echo ""
echo -e "${BOLD}Step 6 — Write findings to file:${NC}"
cmd "cat > /opt/course/8/controlplane-components.txt <<'EOF'"
cat <<'CONTENT'
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
EOF
CONTENT

separator
expected "/opt/course/8/controlplane-components.txt:
  kubelet: process
  kube-apiserver: static-pod
  kube-scheduler: static-pod
  kube-controller-manager: static-pod
  etcd: static-pod
  dns: pod coredns"
