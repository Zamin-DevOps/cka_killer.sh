#!/bin/bash
# DESC: Upgrade K8s version on worker node & join cluster
# NODE: cka3962

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

print_header "Q8 | Update Kubernetes Version and Join Cluster"

print_section "Task"
print_task "Update node cka3962-node1 to same K8s version as controlplane"
print_task "Join cka3962-node1 to the cluster using kubeadm"
echo ""

print_section "Environment Info"
echo -e "  Controlplane : ${CYAN}cka3962${RESET}"
echo -e "  Worker node  : ${CYAN}cka3962-node1${RESET} (SSH from controlplane)"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Check controlplane version:${RESET}"
print_cmd "k get node"
echo ""

echo -e "${BOLD}Step 2 - SSH to worker node:${RESET}"
print_cmd "ssh cka3962-node1"
print_cmd "sudo -i"
echo ""

echo -e "${BOLD}Step 3 - Check current versions on worker:${RESET}"
print_cmd "kubectl version"
print_cmd "kubelet --version"
print_cmd "kubeadm version"
echo ""

echo -e "${BOLD}Step 4 - Install matching kubectl + kubelet (example: 1.35.2):${RESET}"
print_cmd "apt update"
print_cmd "apt show kubectl -a | grep 1.35"
print_cmd "apt install kubectl=1.35.2-1.1 kubelet=1.35.2-1.1"
print_cmd "kubelet --version   # verify"
echo ""

echo -e "${BOLD}Step 5 - Restart kubelet on worker:${RESET}"
print_cmd "service kubelet restart"
print_cmd "service kubelet status   # will show error until joined"
echo ""

echo -e "${BOLD}Step 6 - Back on CONTROLPLANE - generate join command:${RESET}"
print_cmd "exit   # exit worker node"
print_cmd "sudo -i"
print_cmd "kubeadm token create --print-join-command"
echo ""

echo -e "${BOLD}Step 7 - Back on WORKER - run join command:${RESET}"
print_cmd "ssh cka3962-node1"
print_cmd "kubeadm join <IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
echo ""

echo -e "${BOLD}Step 8 - Verify from controlplane:${RESET}"
print_cmd "k get node"
echo ""

print_section "Expected Result"
echo "  NAME            STATUS   ROLES           VERSION"
echo "  cka3962         Ready    control-plane   v1.35.2"
echo "  cka3962-node1   Ready    <none>          v1.35.2"
echo ""

print_warn "If kubeadm join fails, try: kubeadm reset && kubeadm join ..."
print_hint "kubeadm upgrade node only works if the node is already in the cluster"
print_note "kubeadm is usually already at the target version — only kubectl + kubelet need upgrading"
divider
