#!/bin/bash
# DESC: Deployment - one Pod per node via podAntiAffinity
# NODE: cka2556

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-tiger"

print_header "Q12 | Deployment on All Nodes (one Pod per node)"

print_section "Task"
echo -e "  Namespace     : ${CYAN}$NS${RESET}"
echo -e "  Name          : ${CYAN}deploy-important${RESET}"
echo -e "  Replicas      : ${CYAN}3${RESET}"
echo -e "  Label         : ${CYAN}id=very-important${RESET}"
echo -e "  Container 1   : ${CYAN}container1${RESET} - image: nginx:1-alpine"
echo -e "  Container 2   : ${CYAN}container2${RESET} - image: google/pause"
echo -e "  Constraint    : ${CYAN}Max 1 Pod per node (topologyKey: kubernetes.io/hostname)${RESET}"
echo ""
print_note "With 2 worker nodes + 3 replicas → 1 Pod will remain Pending (by design)"
echo ""

print_section "Environment Setup"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"
print_success "Namespace $NS ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
print_cmd "k -n $NS create deployment --image=nginx:1-alpine deploy-important --dry-run=client -o yaml > 12.yaml"
print_cmd "vim 12.yaml"
echo ""

echo -e "${BOLD}Method A - podAntiAffinity (classic):${RESET}"
cat <<'EOF'
  spec:
    replicas: 3
    selector:
      matchLabels:
        id: very-important
    template:
      metadata:
        labels:
          id: very-important
      spec:
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: id
                  operator: In
                  values:
                  - very-important
              topologyKey: kubernetes.io/hostname
        containers:
        - image: nginx:1-alpine
          name: container1
        - image: google/pause
          name: container2
EOF
echo ""

echo -e "${BOLD}Method B - topologySpreadConstraints (modern):${RESET}"
cat <<'EOF'
  spec:
    template:
      spec:
        topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              id: very-important
        containers:
        - image: nginx:1-alpine
          name: container1
        - image: google/pause
          name: container2
EOF
echo ""

print_cmd "k apply -f 12.yaml"
echo ""

print_section "Verify"
print_cmd "k -n $NS get deploy -l id=very-important"
print_cmd "k -n $NS get pod -o wide -l id=very-important"
echo ""

print_hint "READY shows 2/3 — the 3rd Pod is Pending (no node available)"
print_hint "kubectl describe on Pending Pod shows the scheduling failure reason"
divider
