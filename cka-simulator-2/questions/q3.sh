#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "3 — Kubelet Client/Server Certificate Info" \
"Solve on: ssh cka5248  (then ssh cka5248-node1)

Node cka5248-node1 was added using kubeadm TLS bootstrapping.

Find Issuer and Extended Key Usage for:
  1. Kubelet CLIENT cert  — used for outgoing connections TO kube-apiserver
  2. Kubelet SERVER cert  — used for incoming connections FROM kube-apiserver

Write findings to: /opt/course/3/certificate-info.txt

Format:
  Issuer: CN = <value>
  X509v3 Extended Key Usage: <value>
  Issuer: CN = <value>
  X509v3 Extended Key Usage: <value>"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/3
info "Connect to worker node: ssh cka5248-node1"
info "Then: sudo -i"
info "Cert files are in: /var/lib/kubelet/pki/"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  CLIENT cert → kubelet authenticates itself TO apiserver"
echo "    File:   /var/lib/kubelet/pki/kubelet-client-current.pem"
echo "    Issuer: kubernetes CA  (Kubernetes itself signed it)"
echo "    Usage:  TLS Web Client Authentication"
echo ""
echo "  SERVER cert → apiserver connects TO kubelet (logs, exec, port-forward)"
echo "    File:   /var/lib/kubelet/pki/kubelet.crt"
echo "    Issuer: node itself  (self-signed by kubelet)"
echo "    Usage:  TLS Web Server Authentication"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — SSH to worker node:${NC}"
cmd "ssh cka5248-node1"
cmd "sudo -i"
cmd "find /var/lib/kubelet/pki/"

echo ""
echo -e "${BOLD}Step 2 — Inspect CLIENT certificate:${NC}"
cmd "openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep Issuer"
cmd "openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet-client-current.pem | grep 'Extended Key Usage' -A1"

echo ""
echo -e "${BOLD}Step 3 — Inspect SERVER certificate:${NC}"
cmd "openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep Issuer"
cmd "openssl x509 -noout -text -in /var/lib/kubelet/pki/kubelet.crt | grep 'Extended Key Usage' -A1"

echo ""
echo -e "${BOLD}Step 4 — Write to file (on cka5248, not node1):${NC}"
cmd "exit   # back to cka5248"
cmd "cat > /opt/course/3/certificate-info.txt <<EOF"
cat <<'CONTENT'
Issuer: CN = kubernetes
X509v3 Extended Key Usage: TLS Web Client Authentication
Issuer: CN = cka5248-node1-ca@<timestamp>
X509v3 Extended Key Usage: TLS Web Server Authentication
EOF
CONTENT

separator
expected "/opt/course/3/certificate-info.txt:
  Issuer: CN = kubernetes
  X509v3 Extended Key Usage: TLS Web Client Authentication
  Issuer: CN = cka5248-node1-ca@1730211854
  X509v3 Extended Key Usage: TLS Web Server Authentication"
