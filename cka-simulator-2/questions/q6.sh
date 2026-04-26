#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "6 — Fix Kubelet" \
"Solve on: ssh cka1024

The kubelet on controlplane node cka1024 is NOT running.

Tasks:
  a) Find the issue and fix the kubelet
  b) Confirm the node is in Ready state
  c) Create a Pod named 'success' in namespace 'default'
     using image: nginx:1-alpine"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."

KUBELET_CONF="/usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf"

# Only break if kubelet is currently running (so we don't double-break)
if systemctl is-active kubelet &>/dev/null; then
  REAL_PATH=$(which kubelet 2>/dev/null || echo "/usr/bin/kubelet")
  # Inject wrong path into ExecStart
  if [[ -f "$KUBELET_CONF" ]]; then
    sudo sed -i "s|ExecStart=.*kubelet |ExecStart=/usr/local/bin/kubelet |g" "$KUBELET_CONF" 2>/dev/null
    sudo systemctl daemon-reload 2>/dev/null
    sudo systemctl stop kubelet 2>/dev/null
    warn "Kubelet stopped and ExecStart path broken intentionally!"
  else
    warn "kubelet service conf not found at $KUBELET_CONF — skipping break"
  fi
else
  warn "Kubelet already not running — environment is ready to fix"
fi

info "Current kubelet status:"
systemctl is-active kubelet 2>/dev/null || echo "  inactive / failed"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Kubelet runs as a systemd service"
echo "  Config file: /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf"
echo "  ExecStart line tells systemd WHERE the kubelet binary is"
echo "  If binary path is wrong → kubelet fails with exit-code 203/EXEC"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Check if kubelet is running:${NC}"
cmd "service kubelet status"
cmd "ps aux | grep kubelet"

echo ""
echo -e "${BOLD}Step 2 — Try to start it and check why it fails:${NC}"
cmd "service kubelet start"
cmd "service kubelet status"
cmd "# Look for: Main process exited, code=exited, status=203/EXEC"
cmd "# 203/EXEC means binary not found at the path specified"

echo ""
echo -e "${BOLD}Step 3 — Find where kubelet binary ACTUALLY is:${NC}"
cmd "whereis kubelet"
cmd "which kubelet"
cmd "# Usually: /usr/bin/kubelet"

echo ""
echo -e "${BOLD}Step 4 — Check what path is configured in service file:${NC}"
cmd "cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf"
cmd "# Look at ExecStart= line"
cmd "# Wrong:  ExecStart=/usr/local/bin/kubelet ..."
cmd "# Correct: ExecStart=/usr/bin/kubelet ..."

echo ""
echo -e "${BOLD}Step 5 — Fix the path:${NC}"
cmd "vim /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf"
cat <<'CONTENT'

  # Change this line:
  ExecStart=/usr/local/bin/kubelet $KUBELET_KUBECONFIG_ARGS ...
  # To:
  ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS ...
CONTENT

echo ""
echo -e "${BOLD}Step 6 — Reload and restart:${NC}"
cmd "systemctl daemon-reload"
cmd "service kubelet restart"
cmd "service kubelet status"
cmd "# Should show: Active: active (running)"

echo ""
echo -e "${BOLD}Step 7 — Wait for node to be Ready then create Pod:${NC}"
cmd "kubectl get node"
cmd "kubectl run success --image=nginx:1-alpine"
cmd "kubectl get pod success"

separator
expected "Node:    cka1024   Ready   control-plane
Pod:     success   1/1     Running"
