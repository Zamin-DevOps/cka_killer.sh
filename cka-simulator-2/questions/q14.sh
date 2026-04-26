#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "14 — Find out Cluster Information" \
"Solve on: ssh cka8448

Find the following information about the cluster:
  1. How many controlplane nodes?
  2. How many worker nodes (non-controlplane)?
  3. What is the Service CIDR?
  4. Which CNI plugin is configured and where is its config file?
  5. Which suffix will static pods have that run on cka8448?

Write answers to: /opt/course/14/cluster-info

Format:
  1: [ANSWER]
  2: [ANSWER]
  3: [ANSWER]
  4: [ANSWER]
  5: [ANSWER]"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/14
info "No pre-setup needed — investigate the running cluster"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Service CIDR    → defined in kube-apiserver manifest"
echo "  CNI config      → lives in /etc/cni/net.d/"
echo "  Static pod suffix → hyphen + node hostname  e.g. -cka8448"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Question 1 & 2 — Count controlplane and worker nodes:${NC}"
cmd "kubectl get nodes"
cmd "kubectl get nodes | grep control-plane | wc -l   # controlplane count"
cmd "kubectl get nodes | grep -v control-plane | grep -v NAME | wc -l  # worker count"

echo ""
echo -e "${BOLD}Question 3 — Service CIDR:${NC}"
cmd "sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep range"
cmd "# Look for: --service-cluster-ip-range=10.96.0.0/12"

echo ""
echo -e "${BOLD}Question 4 — CNI plugin and config file:${NC}"
cmd "find /etc/cni/net.d/"
cmd "cat /etc/cni/net.d/*.conflist 2>/dev/null || cat /etc/cni/net.d/*.conf 2>/dev/null"
cmd "# Common CNIs: weave (10-weave.conflist), flannel, calico, cilium"

echo ""
echo -e "${BOLD}Question 5 — Static pod suffix:${NC}"
cmd "kubectl get nodes"
cmd "# Suffix = hyphen + node name = -cka8448"
cmd "# Example: etcd-cka8448, kube-apiserver-cka8448"

echo ""
echo -e "${BOLD}Write answers to file:${NC}"
cmd "vim /opt/course/14/cluster-info"
cat <<'CONTENT'

# Example content (fill with real values):
1: 1
2: 0
3: 10.96.0.0/12
4: Weave, /etc/cni/net.d/10-weave.conflist
5: -cka8448
CONTENT

separator
expected "/opt/course/14/cluster-info:
  1: 1
  2: 0
  3: 10.96.0.0/12
  4: Weave, /etc/cni/net.d/10-weave.conflist
  5: -cka8448"
