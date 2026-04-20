#!/bin/bash
# DESC: Storage - PV, PVC, Deployment with volume mount
# NODE: cka7968

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-t230"

print_header "Q6 | Storage - PV, PVC, Pod Volume"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create PV ${CYAN}safari-pv${RESET}: 2Gi, ReadWriteOnce, hostPath=/Volumes/Data, no storageClass"
echo -e "  ${BOLD}2.${RESET} Create PVC ${CYAN}safari-pvc${RESET} in ns ${CYAN}project-t230${RESET}: 2Gi, RWO, no storageClass"
echo -e "  ${BOLD}3.${RESET} Create Deployment ${CYAN}safari${RESET} in ns ${CYAN}project-t230${RESET}: image=httpd:2-alpine, mount PVC at /tmp/safari-data"
echo ""

print_section "Environment Setup"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"
print_success "Namespace $NS ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Create PersistentVolume:${RESET}"
print_cmd "vim 6_pv.yaml"
echo ""
cat <<'EOF'
  # 6_pv.yaml
  kind: PersistentVolume
  apiVersion: v1
  metadata:
    name: safari-pv
  spec:
    capacity:
      storage: 2Gi
    accessModes:
      - ReadWriteOnce
    hostPath:
      path: "/Volumes/Data"
EOF
echo ""
print_cmd "k apply -f 6_pv.yaml"
echo ""

echo -e "${BOLD}Step 2 - Create PersistentVolumeClaim:${RESET}"
print_cmd "vim 6_pvc.yaml"
echo ""
cat <<'EOF'
  # 6_pvc.yaml
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: safari-pvc
    namespace: project-t230
  spec:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 2Gi
EOF
echo ""
print_cmd "k apply -f 6_pvc.yaml"
print_cmd "k -n $NS get pv,pvc"
echo ""

echo -e "${BOLD}Step 3 - Create Deployment with volume:${RESET}"
print_cmd "k -n $NS create deploy safari --image=httpd:2-alpine --dry-run=client -o yaml > 6_dep.yaml"
print_cmd "vim 6_dep.yaml"
echo ""
echo -e "  Add under ${CYAN}spec.template.spec${RESET}:"
echo '    volumes:'
echo '    - name: data'
echo '      persistentVolumeClaim:'
echo '        claimName: safari-pvc'
echo ''
echo -e "  Add under ${CYAN}spec.template.spec.containers[0]${RESET}:"
echo '    volumeMounts:'
echo '    - name: data'
echo '      mountPath: /tmp/safari-data'
echo ""
print_cmd "k apply -f 6_dep.yaml"
echo ""

print_section "Verify"
print_cmd "k -n $NS get pv,pvc"
print_cmd "k -n $NS get deploy safari"
print_cmd "k -n $NS describe pod \$(k -n $NS get pod -l app=safari -o name | head -1) | grep -A2 Mounts:"
echo ""

print_hint "PV and PVC must both have no storageClassName to bind to each other"
print_hint "PV status should show 'Bound' after PVC is created"
divider
