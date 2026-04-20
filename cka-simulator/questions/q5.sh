#!/bin/bash
# DESC: Kustomize - Remove ConfigMap, Add HPA for staging & prod
# NODE: cka5774

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

BASE_DIR="/opt/course/5/api-gateway"

print_header "Q5 | Kustomize - Configure HPA Autoscaler"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Remove ConfigMap ${CYAN}horizontal-scaling-config${RESET} completely (base + overlays)"
echo -e "  ${BOLD}2.${RESET} Add HPA ${CYAN}api-gateway${RESET} in base: min=2 max=4 cpu=50%"
echo -e "  ${BOLD}3.${RESET} In ${CYAN}prod${RESET} overlay: override HPA maxReplicas to ${CYAN}6${RESET}"
echo -e "  ${BOLD}4.${RESET} Apply changes for both ${CYAN}staging${RESET} and ${CYAN}prod${RESET}"
echo ""

print_section "Environment Setup"

mkdir -p "$BASE_DIR/base" "$BASE_DIR/staging" "$BASE_DIR/prod"

# Namespaces
kubectl get ns api-gateway-staging &>/dev/null || kubectl create ns api-gateway-staging &>/dev/null
kubectl get ns api-gateway-prod    &>/dev/null || kubectl create ns api-gateway-prod    &>/dev/null

# ── BASE ──────────────────────────────────────────────────────
cat > "$BASE_DIR/base/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - api-gateway.yaml
EOF

cat > "$BASE_DIR/base/api-gateway.yaml" <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-gateway
  namespace: NAMESPACE_REPLACE
---
apiVersion: v1
data:
  horizontal-scaling: "70"
kind: ConfigMap
metadata:
  name: horizontal-scaling-config
  namespace: NAMESPACE_REPLACE
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: NAMESPACE_REPLACE
spec:
  replicas: 1
  selector:
    matchLabels:
      id: api-gateway
  template:
    metadata:
      labels:
        id: api-gateway
    spec:
      containers:
      - image: httpd:2-alpine
        name: httpd
      serviceAccountName: api-gateway
EOF

# ── STAGING ───────────────────────────────────────────────────
cat > "$BASE_DIR/staging/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base
patches:
  - path: api-gateway.yaml
transformers:
  - |-
    apiVersion: builtin
    kind: NamespaceTransformer
    metadata:
      name: notImportantHere
      namespace: api-gateway-staging
EOF

cat > "$BASE_DIR/staging/api-gateway.yaml" <<'EOF'
apiVersion: v1
data:
  horizontal-scaling: "60"
kind: ConfigMap
metadata:
  name: horizontal-scaling-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: staging
EOF

# ── PROD ──────────────────────────────────────────────────────
cat > "$BASE_DIR/prod/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base
patches:
  - path: api-gateway.yaml
transformers:
  - |-
    apiVersion: builtin
    kind: NamespaceTransformer
    metadata:
      name: notImportantHere
      namespace: api-gateway-prod
EOF

cat > "$BASE_DIR/prod/api-gateway.yaml" <<'EOF'
apiVersion: v1
data:
  horizontal-scaling: "80"
kind: ConfigMap
metadata:
  name: horizontal-scaling-config
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: prod
EOF

# Apply initial state
kubectl kustomize "$BASE_DIR/staging" | kubectl apply -f - &>/dev/null || true
kubectl kustomize "$BASE_DIR/prod"    | kubectl apply -f - &>/dev/null || true

print_success "Kustomize structure created at: $BASE_DIR"
echo ""

print_section "Directory Structure"
echo "  $BASE_DIR/"
echo "  ├── base/"
echo "  │   ├── kustomization.yaml"
echo "  │   └── api-gateway.yaml     ← Edit: remove ConfigMap, add HPA"
echo "  ├── staging/"
echo "  │   ├── kustomization.yaml"
echo "  │   └── api-gateway.yaml     ← Edit: remove ConfigMap patch"
echo "  └── prod/"
echo "      ├── kustomization.yaml"
echo "      └── api-gateway.yaml     ← Edit: remove ConfigMap patch, add maxReplicas: 6"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Explore current state:${RESET}"
print_cmd "cd $BASE_DIR && k kustomize staging"
print_cmd "cd $BASE_DIR && k kustomize prod"
echo ""

echo -e "${BOLD}Step 2 - Edit base/api-gateway.yaml:${RESET}"
print_cmd "vim $BASE_DIR/base/api-gateway.yaml"
echo ""
echo -e "  ${RED}Remove${RESET} the ConfigMap block entirely"
echo -e "  ${GREEN}Add${RESET} this HPA at the TOP of the file:"
cat <<'HPAYAML'
  ---
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: api-gateway
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: api-gateway
    minReplicas: 2
    maxReplicas: 4
    metrics:
      - type: Resource
        resource:
          name: cpu
          target:
            type: Utilization
            averageUtilization: 50
HPAYAML
echo ""

echo -e "${BOLD}Step 3 - Edit staging/api-gateway.yaml:${RESET}"
print_cmd "vim $BASE_DIR/staging/api-gateway.yaml"
echo -e "  ${RED}Remove${RESET} the ConfigMap block (keep only the Deployment patch)"
echo ""

echo -e "${BOLD}Step 4 - Edit prod/api-gateway.yaml:${RESET}"
print_cmd "vim $BASE_DIR/prod/api-gateway.yaml"
echo -e "  ${RED}Remove${RESET} the ConfigMap block"
echo -e "  ${GREEN}Add${RESET} HPA patch with maxReplicas: 6:"
echo ""
echo -e "    apiVersion: autoscaling/v2"
echo -e "    kind: HorizontalPodAutoscaler"
echo -e "    metadata:"
echo -e "      name: api-gateway"
echo -e "    spec:"
echo -e "      ${GREEN}maxReplicas: 6${RESET}"
echo ""

echo -e "${BOLD}Step 5 - Verify builds:${RESET}"
print_cmd "k kustomize $BASE_DIR/staging | grep maxReplicas -B5"
print_cmd "k kustomize $BASE_DIR/prod    | grep maxReplicas -B5"
echo ""

echo -e "${BOLD}Step 6 - Apply both:${RESET}"
print_cmd "k kustomize $BASE_DIR/staging | kubectl apply -f -"
print_cmd "k kustomize $BASE_DIR/prod    | kubectl apply -f -"
echo ""

echo -e "${BOLD}Step 7 - Delete old ConfigMaps manually (Kustomize doesn't track deletions):${RESET}"
print_cmd "k -n api-gateway-staging delete cm horizontal-scaling-config"
print_cmd "k -n api-gateway-prod    delete cm horizontal-scaling-config"
echo ""

print_section "Verify"
print_cmd "k -n api-gateway-staging get hpa"
print_cmd "k -n api-gateway-prod get hpa"
echo ""

print_hint "staging HPA maxReplicas should be 4, prod should be 6"
print_note "Kustomize has no state — it never auto-deletes remote resources"
divider
