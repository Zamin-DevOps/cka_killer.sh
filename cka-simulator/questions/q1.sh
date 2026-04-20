#!/bin/bash
# DESC: Kubeconfig - Extract contexts, current-context, cert
# NODE: cka9412

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

KUBECONFIG_FILE="/opt/course/1/kubeconfig"
OUT_DIR="/opt/course/1"

print_header "Q1 | Kubeconfig Extraction"

print_section "Task"
print_task "Extract info from kubeconfig: $KUBECONFIG_FILE"
echo ""
echo -e "  ${BOLD}1.${RESET} Write all context names     → $OUT_DIR/contexts"
echo -e "  ${BOLD}2.${RESET} Write current context name  → $OUT_DIR/current-context"
echo -e "  ${BOLD}3.${RESET} Write client-cert of user   → $OUT_DIR/cert"
echo -e "      (user: account-0027, base64-decoded)"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"

# Create a realistic mock kubeconfig for practice
cat > "$KUBECONFIG_FILE" <<'EOF'
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://10.30.110.30:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: admin@internal
  name: cluster-admin
- context:
    cluster: kubernetes
    user: account-0027@internal
  name: cluster-w100
- context:
    cluster: kubernetes
    user: account-0028@internal
  name: cluster-w200
current-context: cluster-w200
kind: Config
preferences: {}
users:
- name: admin@internal
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmZha2UKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpmYWtlCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
- name: account-0027@internal
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN2RENDQWFRQ0ZIWWRqU1pGS0N5VUNSMUIybmFYQ2cvVWpTSExNQTBHQ1NxR1NJYjNEUUVCQ3dVQU1CVXgKRXpBUkJnTlZCQU1UQ210MVltVnlibVYwWlhNd0hoY05NalF4TURJNE1Ua3dPVFV3V2hjTk1qWXdNekV5TVRrdwpPVFV3V2pBZ01SNHdIQVlEVlFRRERCVmhZMk52ZFc1MExUQXdNamRBYVc1MFpYSnVZV3d3Z2dFaU1BMEdDU3FHClNJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUURwVXNRRERFVys0OEF2Wm1LYktTMndtc1phMGd5K2t6aWkKY1pEcFpnOG1nTys1MGpObkhRNElDcUFqRzNmRkhtUG5idWowc1pHWGYreW0wSjJkVkw5andHU3Q1TlZvTHJqagpUd2xCRzYzK2s0alJCeExCdjY0NzlpUFhYazBnaVAzOFRBb1MvL2R0SitPOGlzYlJNbmxiOWFJNUwySll4SGZOClZMMnFyRjlhckxmMUROK2gwaGF2RnhuOW5vSi9pWngvcWIvRkhnZVpxblRmN3pSNk9vdVJ1V0hHNTIzam5UcUEKMDZLK2c0azJvNmhnM3U3Sk0vY05iSEZNN1MycVNCRGtTMjY2Skp0dk10QytjcHNtZy9lVW5EaEEyMXRUYTR2ZwpsYnB3NnZ4bkpjd010NG4wS2FBZVMwajRMM09DODY5YWxweTFqdkkzQVRqRmp1Y2tMRVNMQWdNQkFBRXdEUVlKCktvWklodmNOQVFFTEJRQURnZ0VCQURRUUxHWVpvVVNyYnBnRlY2OXNIdk11b3huMllVdDFCNUZCbVFyeHdPbGkKZGVtOTM2cTJaTE1yMzRyUTVyQzF1VFFEcmFXWGE0NHlIbVZaMDd0ZElOa1Yydm9JZXhIalg5MWdWQytMaXJRcQpJS0d4aW9rOUNLTEU3TlJlRjYzcHAvN0JOZTcvUDZjT1JoME8yRURNNFRnSFhMcFhydDd0ZFBFWHd2ck4xdE1RCno1YXY5UG81VGQ0VmYwcGFPRHRsYWh3aElaNks3Y3RnVkdUMUtkUWxuMXFYRGIvVndxM1Z5WUJBSktsbU91OWwKYmozbm12YzdEOTllOXA0eTRHRkNrQWxieHY5VEQwVDR5dllnVkZ0UlRWYkdBa21hendVSHJmY1FuUlRWZktvegpTZnNZUnk2TDFSS3hqd2g3NEtuaEtKeiswOUpxWHByN01WZFFnamgwUmR3PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpmYWtlCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
- name: account-0028@internal
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCmZha2UKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpmYWtlCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
EOF

print_success "Kubeconfig file created at: $KUBECONFIG_FILE"

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Get all context names:${RESET}"
print_cmd "k --kubeconfig $KUBECONFIG_FILE config get-contexts -oname"
print_cmd "k --kubeconfig $KUBECONFIG_FILE config get-contexts -oname > $OUT_DIR/contexts"
echo ""

echo -e "${BOLD}Step 2 - Get current context:${RESET}"
print_cmd "k --kubeconfig $KUBECONFIG_FILE config current-context"
print_cmd "k --kubeconfig $KUBECONFIG_FILE config current-context > $OUT_DIR/current-context"
echo ""

echo -e "${BOLD}Step 3 - Extract client-cert of account-0027 (base64 decoded):${RESET}"
print_cmd "k --kubeconfig $KUBECONFIG_FILE config view --raw -ojsonpath='{.users[?(@.name==\"account-0027@internal\")].user.client-certificate-data}' | base64 -d > $OUT_DIR/cert"
echo ""

print_section "Expected Output Structure"
echo "  $OUT_DIR/"
echo "  ├── kubeconfig          (given)"
echo "  ├── contexts            ← cluster-admin / cluster-w100 / cluster-w200"
echo "  ├── current-context     ← cluster-w200"
echo "  └── cert                ← -----BEGIN CERTIFICATE----- ..."
echo ""

print_hint "Use 'cat $OUT_DIR/contexts' to verify your answer"
print_hint "Use 'cat $OUT_DIR/cert' to verify the certificate is PEM format"
divider
