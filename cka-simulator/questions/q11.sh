#!/bin/bash
# DESC: DaemonSet on ALL nodes including controlplane (tolerations)
# NODE: cka2556

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-tiger"

print_header "Q11 | DaemonSet on All Nodes"

print_section "Task"
echo -e "  Namespace   : ${CYAN}$NS${RESET}"
echo -e "  Name        : ${CYAN}ds-important${RESET}"
echo -e "  Image       : ${CYAN}httpd:2-alpine${RESET}"
echo -e "  Labels      : ${CYAN}id=ds-important, uuid=18426a0b-5f59-4e10-923f-c0e078e82462${RESET}"
echo -e "  Resources   : ${CYAN}cpu: 10m, memory: 10Mi (requests)${RESET}"
echo -e "  Runs on     : ${CYAN}ALL nodes including controlplane${RESET}"
echo ""

print_section "Environment Setup"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"
print_success "Namespace $NS ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Generate base yaml from a Deployment (DaemonSet can't be created directly):${RESET}"
print_cmd "k -n $NS create deployment --image=httpd:2-alpine ds-important --dry-run=client -o yaml > 11.yaml"
print_cmd "vim 11.yaml"
echo ""

echo -e "${BOLD}Key changes to make in 11.yaml:${RESET}"
echo ""
echo -e "  ${RED}Change:${RESET}  kind: Deployment          → ${GREEN}kind: DaemonSet${RESET}"
echo -e "  ${RED}Remove:${RESET}  replicas: 1"
echo -e "  ${RED}Remove:${RESET}  strategy: {}"
echo -e "  ${GREEN}Add:${RESET}    labels to metadata, selector.matchLabels, and template.metadata.labels:"
echo "           id: ds-important"
echo "           uuid: 18426a0b-5f59-4e10-923f-c0e078e82462"
echo -e "  ${GREEN}Add:${RESET}    resources.requests under containers:"
echo "           cpu: 10m"
echo "           memory: 10Mi"
echo -e "  ${GREEN}Add:${RESET}    tolerations under spec.template.spec:"
echo "           - effect: NoSchedule"
echo "             key: node-role.kubernetes.io/control-plane"
echo ""

echo -e "${BOLD}Full 11.yaml should look like:${RESET}"
cat <<'EOF'
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
    labels:
      id: ds-important
      uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
    name: ds-important
    namespace: project-tiger
  spec:
    selector:
      matchLabels:
        id: ds-important
        uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
    template:
      metadata:
        labels:
          id: ds-important
          uuid: 18426a0b-5f59-4e10-923f-c0e078e82462
      spec:
        containers:
        - image: httpd:2-alpine
          name: ds-important
          resources:
            requests:
              cpu: 10m
              memory: 10Mi
        tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/control-plane
EOF
echo ""

print_cmd "k apply -f 11.yaml"
echo ""

print_section "Verify"
print_cmd "k -n $NS get ds ds-important"
print_cmd "k -n $NS get pod -l id=ds-important -o wide"
echo ""

print_hint "Without the toleration, the Pod won't schedule on controlplane nodes"
print_hint "DESIRED count should equal number of nodes in your cluster"
divider
