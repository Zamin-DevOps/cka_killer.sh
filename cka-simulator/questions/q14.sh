#!/bin/bash
# DESC: Check kube-apiserver certificate expiration with openssl & kubeadm
# NODE: cka9412

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

OUT_DIR="/opt/course/14"

print_header "Q14 | Check How Long Certificates are Valid"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Check kube-apiserver cert validity using ${CYAN}openssl${RESET}"
echo -e "     Write expiration date to ${CYAN}$OUT_DIR/expiration${RESET}"
echo -e "  ${BOLD}2.${RESET} Confirm using ${CYAN}kubeadm certs check-expiration${RESET} (same date?)"
echo -e "  ${BOLD}3.${RESET} Write renewal command to ${CYAN}$OUT_DIR/kubeadm-renew-certs.sh${RESET}"
echo ""

print_section "Environment Setup"
sudo mkdir -p "$OUT_DIR" 2>/dev/null || mkdir -p "$OUT_DIR"
print_success "Output directory ready: $OUT_DIR"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Find the apiserver certificate:${RESET}"
print_cmd "sudo find /etc/kubernetes/pki | grep apiserver"
echo ""
echo -e "  Look for: ${CYAN}/etc/kubernetes/pki/apiserver.crt${RESET}"
echo ""

echo -e "${BOLD}Step 2 - Check expiration with openssl:${RESET}"
print_cmd "sudo openssl x509 -noout -text -in /etc/kubernetes/pki/apiserver.crt | grep Validity -A2"
echo ""
echo -e "  Output looks like:"
echo "    Validity"
echo "        Not Before: Oct 29 14:14:27 2024 GMT"
echo "        Not After : Oct 29 14:19:27 2025 GMT   ← copy this date"
echo ""

echo -e "${BOLD}Step 3 - Write expiration date to file:${RESET}"
print_cmd "sudo openssl x509 -noout -enddate -in /etc/kubernetes/pki/apiserver.crt | cut -d= -f2 > $OUT_DIR/expiration"
print_cmd "cat $OUT_DIR/expiration"
echo ""

echo -e "${BOLD}Step 4 - Verify with kubeadm (compare dates):${RESET}"
print_cmd "sudo kubeadm certs check-expiration | grep apiserver"
echo ""

echo -e "${BOLD}Step 5 - Write renewal command to file:${RESET}"
print_cmd "echo 'kubeadm certs renew apiserver' > $OUT_DIR/kubeadm-renew-certs.sh"
print_cmd "cat $OUT_DIR/kubeadm-renew-certs.sh"
echo ""

print_section "Verify"
print_cmd "cat $OUT_DIR/expiration"
print_cmd "cat $OUT_DIR/kubeadm-renew-certs.sh"
echo ""

print_section "Output File Structure"
echo "  $OUT_DIR/"
echo "  ├── expiration           ← e.g. 'Oct 29 14:19:27 2025 GMT'"
echo "  └── kubeadm-renew-certs.sh  ← 'kubeadm certs renew apiserver'"
echo ""

print_hint "Both openssl and kubeadm should show the same expiration date"
print_hint "kubeadm certs renew apiserver will also restart the apiserver pod"
print_note "Certificates are located at /etc/kubernetes/pki/"
divider
