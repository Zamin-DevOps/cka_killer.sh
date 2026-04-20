#!/bin/bash
# DESC: CoreDNS - add custom-domain alongside cluster.local
# NODE: cka5774

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

OUT_DIR="/opt/course/16"

print_header "Q16 | Update CoreDNS Configuration"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Backup existing CoreDNS ConfigMap to ${CYAN}$OUT_DIR/coredns_backup.yaml${RESET}"
echo -e "  ${BOLD}2.${RESET} Add ${CYAN}custom-domain${RESET} to CoreDNS config so both work:"
echo "       SERVICE.NAMESPACE.cluster.local"
echo "       SERVICE.NAMESPACE.custom-domain"
echo -e "  ${BOLD}3.${RESET} Test with nslookup from a busybox Pod"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"
print_success "Output directory ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Backup CoreDNS ConfigMap:${RESET}"
print_cmd "k -n kube-system get cm coredns -oyaml > $OUT_DIR/coredns_backup.yaml"
print_cmd "cat $OUT_DIR/coredns_backup.yaml"
echo ""

echo -e "${BOLD}Step 2 - Edit CoreDNS ConfigMap:${RESET}"
print_cmd "k -n kube-system edit cm coredns"
echo ""
echo -e "  Find this line in the Corefile:"
echo -e "    ${RED}kubernetes cluster.local in-addr.arpa ip6.arpa {${RESET}"
echo ""
echo -e "  Change it to:"
echo -e "    ${GREEN}kubernetes custom-domain cluster.local in-addr.arpa ip6.arpa {${RESET}"
echo ""

echo -e "${BOLD}Step 3 - Restart CoreDNS deployment:${RESET}"
print_cmd "k -n kube-system rollout restart deploy coredns"
print_cmd "k -n kube-system get pod | grep coredns"
echo ""

echo -e "${BOLD}Step 4 - Test with busybox:${RESET}"
print_cmd "k run bb --image=busybox:1 -- sh -c 'sleep 1d'"
print_cmd "k exec -it bb -- sh"
echo ""
echo "  Inside the pod:"
echo "  nslookup kubernetes.default.svc.cluster.local"
echo "  nslookup kubernetes.default.svc.custom-domain"
echo ""

print_section "Expected Test Output"
echo "  Both should resolve to: 10.96.0.1  (or similar ClusterIP)"
echo ""

print_section "Rollback if Needed"
print_cmd "k delete -f $OUT_DIR/coredns_backup.yaml"
print_cmd "k apply  -f $OUT_DIR/coredns_backup.yaml"
print_cmd "k -n kube-system rollout restart deploy coredns"
echo ""

print_hint "Only add 'custom-domain' to the EXISTING kubernetes line — don't create a new block"
print_warn "Syntax errors in Corefile will break DNS — always restart and verify pods are Running"
print_note "The backup allows fast recovery — always backup before editing CoreDNS"
divider
