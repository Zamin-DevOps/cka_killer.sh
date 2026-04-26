#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "7 — Etcd Operations" \
"Solve on: ssh cka2560

Tasks:
  a) Run 'etcd --version' and store output at:
     /opt/course/7/etcd-version

  b) Make a snapshot of etcd and save it at:
     /opt/course/7/etcd-snapshot.db

Note: etcd runs as a Pod (not installed directly on host)"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/7
info "Checking etcd pod..."
kubectl -n kube-system get pod | grep etcd 2>/dev/null || warn "etcd pod not found — are you on controlplane?"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  etcd is NOT installed as a binary on the host directly"
echo "  It runs as a Static Pod in kube-system namespace"
echo "  → Use 'kubectl exec' to run etcd commands inside the pod"
echo ""
echo "  For snapshot: use etcdctl with TLS certs from etcd.yaml"
echo "  Cert paths are defined in /etc/kubernetes/manifests/etcd.yaml"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Find etcd pod name:${NC}"
cmd "kubectl -n kube-system get pod | grep etcd"
cmd "# e.g.: etcd-cka2560"

echo ""
echo -e "${BOLD}Step 2 — Get etcd version (Part A):${NC}"
cmd "kubectl -n kube-system exec etcd-cka2560 -- etcd --version"
cmd "# Save output:"
cmd "kubectl -n kube-system exec etcd-cka2560 -- etcd --version > /opt/course/7/etcd-version"
cmd "cat /opt/course/7/etcd-version"

echo ""
echo -e "${BOLD}Step 3 — Find cert paths from etcd manifest (Part B):${NC}"
cmd "cat /etc/kubernetes/manifests/etcd.yaml | grep -E 'cert-file|key-file|trusted-ca|listen-client'"
cat <<'CONTENT'

  # Key lines to note:
  # --cert-file=/etc/kubernetes/pki/etcd/server.crt
  # --key-file=/etc/kubernetes/pki/etcd/server.key
  # --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
  # --listen-client-urls=https://127.0.0.1:2379,...
CONTENT

echo ""
echo -e "${BOLD}Step 4 — Take etcd snapshot:${NC}"
cmd "ETCDCTL_API=3 etcdctl snapshot save /opt/course/7/etcd-snapshot.db \\"
cmd "  --cacert /etc/kubernetes/pki/etcd/ca.crt \\"
cmd "  --cert   /etc/kubernetes/pki/etcd/server.crt \\"
cmd "  --key    /etc/kubernetes/pki/etcd/server.key"

echo ""
echo -e "${BOLD}Step 5 — Verify snapshot:${NC}"
cmd "ETCDCTL_API=3 etcdctl snapshot status /opt/course/7/etcd-snapshot.db --write-out=table"

separator
section "BONUS — Restore snapshot (optional, careful!)"
echo "  Since etcd 3.6 → use 'etcdutl' (not etcdctl) for restore"
cmd "etcdutl snapshot restore /opt/course/7/etcd-snapshot.db --data-dir /var/lib/etcd-restored"
cmd "# Then update etcd.yaml to point to new data-dir"

separator
expected "/opt/course/7/etcd-version:
  etcd Version: 3.x.x

/opt/course/7/etcd-snapshot.db:
  Snapshot saved at /opt/course/7/etcd-snapshot.db"
