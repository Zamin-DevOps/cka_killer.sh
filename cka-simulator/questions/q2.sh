#!/bin/bash
# DESC: MinIO Operator - Helm Install + Tenant CRD
# NODE: cka7968

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

OUT_DIR="/opt/course/2"
TENANT_FILE="$OUT_DIR/minio-tenant.yaml"

print_header "Q2 | MinIO Operator, CRD Config, Helm Install"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create Namespace ${CYAN}minio${RESET}"
echo -e "  ${BOLD}2.${RESET} Install Helm chart ${CYAN}minio/operator${RESET} as release ${CYAN}minio-operator${RESET} in ns minio"
echo -e "  ${BOLD}3.${RESET} Add ${CYAN}enableSFTP: true${RESET} under ${CYAN}spec.features${RESET} in the Tenant yaml"
echo -e "  ${BOLD}4.${RESET} Create the Tenant resource from the yaml file"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"

cat > "$TENANT_FILE" <<'EOF'
apiVersion: minio.min.io/v2
kind: Tenant
metadata:
  name: tenant
  namespace: minio
  labels:
    app: minio
spec:
  features:
    bucketDNS: false
    # TODO: add enableSFTP: true here
  image: quay.io/minio/minio:latest
  pools:
    - servers: 1
      name: pool-0
      volumesPerServer: 0
      volumeClaimTemplate:
        apiVersion: v1
        kind: persistentvolumeclaims
        metadata: {}
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 10Mi
          storageClassName: standard
        status: {}
  requestAutoCert: true
EOF

print_success "Tenant yaml created at: $TENANT_FILE"

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Create Namespace:${RESET}"
print_cmd "k create ns minio"
echo ""

echo -e "${BOLD}Step 2 - Check Helm repo & install:${RESET}"
print_cmd "helm repo list"
print_cmd "helm search repo minio"
print_cmd "helm -n minio install minio-operator minio/operator"
print_cmd "helm -n minio ls"
echo ""

echo -e "${BOLD}Step 3 - Edit Tenant yaml to add enableSFTP:${RESET}"
print_cmd "vim $TENANT_FILE"
echo ""
echo -e "  Add under ${CYAN}spec.features${RESET}:"
echo -e "  ${GREEN}    enableSFTP: true${RESET}"
echo ""

echo -e "${BOLD}Step 4 - Check available CRDs then apply Tenant:${RESET}"
print_cmd "k get crd | grep minio"
print_cmd "k describe crd tenants.minio.min.io | grep -i feature -A 20"
print_cmd "k -f $TENANT_FILE apply"
print_cmd "k -n minio get tenant"
echo ""

print_section "Verify"
print_cmd "k -n minio get pod"
print_cmd "k -n minio get tenant"
echo ""

print_hint "CRDs are installed automatically when the Helm chart deploys"
print_hint "The Tenant won't be fully Running — that's OK per the question"
print_note "Operators pattern: Helm deploys operator → operator registers CRDs → you create CRD instances"
divider
