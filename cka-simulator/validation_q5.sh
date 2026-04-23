#!/bin/bash
# ══════════════════════════════════════════════════════════════
# Q5 | Kustomize - ConfigMap Remove + HPA Autoscaler
# NODE: cka5774
# Usage:
#   bash q5_kustomize_validate.sh setup     → creates environment
#   bash q5_kustomize_validate.sh validate  → checks your work
#   bash q5_kustomize_validate.sh apply     → applies to cluster
#   bash q5_kustomize_validate.sh clean     → tears down everything
# ══════════════════════════════════════════════════════════════

BASE_DIR="/opt/course/5/api-gateway"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'

# ── Helpers ───────────────────────────────────────────────────
print_header()  { echo -e "\n${BOLD}${BLUE}════════════════════════════════════════${RESET}"; echo -e "${BOLD}${BLUE}  $1${RESET}"; echo -e "${BOLD}${BLUE}════════════════════════════════════════${RESET}"; }
print_section() { echo -e "\n${BOLD}${CYAN}── $1 ──${RESET}"; }
print_pass()    { echo -e "  ${GREEN}✓ PASS${RESET}  $1"; }
print_fail()    { echo -e "  ${RED}✗ FAIL${RESET}  $1"; }
print_warn()    { echo -e "  ${YELLOW}⚠ WARN${RESET}  $1"; }
print_info()    { echo -e "  ${CYAN}ℹ INFO${RESET}  $1"; }
print_cmd()     { echo -e "  ${YELLOW}▶${RESET} ${BOLD}$1${RESET}"; }
divider()       { echo -e "${BOLD}${BLUE}────────────────────────────────────────${RESET}"; }

PASS_COUNT=0
FAIL_COUNT=0

check() {
  local desc="$1"; local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    print_pass "$desc"; ((PASS_COUNT++))
  else
    print_fail "$desc"; ((FAIL_COUNT++))
    return 1
  fi
}

check_output() {
  local desc="$1"; local cmd="$2"; local pattern="$3"
  local out; out=$(eval "$cmd" 2>/dev/null)
  if echo "$out" | grep -q "$pattern"; then
    print_pass "$desc"; ((PASS_COUNT++))
  else
    print_fail "$desc"
    echo -e "         ${RED}Expected pattern:${RESET} $pattern"
    echo -e "         ${RED}Got:${RESET} $(echo "$out" | head -5)"
    ((FAIL_COUNT++))
    return 1
  fi
}

check_absent() {
  local desc="$1"; local cmd="$2"; local pattern="$3"
  local out; out=$(eval "$cmd" 2>/dev/null)
  if echo "$out" | grep -q "$pattern"; then
    print_fail "$desc — found '$pattern' but it should be ABSENT"
    ((FAIL_COUNT++))
    return 1
  else
    print_pass "$desc"; ((PASS_COUNT++))
  fi
}

# ══════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════
cmd_setup() {
  print_header "Q5 | Environment Setup"

  mkdir -p "$BASE_DIR/base" "$BASE_DIR/staging" "$BASE_DIR/prod"

  # Namespaces (best-effort)
  if command -v kubectl &>/dev/null; then
    kubectl get ns api-gateway-staging &>/dev/null || kubectl create ns api-gateway-staging &>/dev/null
    kubectl get ns api-gateway-prod    &>/dev/null || kubectl create ns api-gateway-prod    &>/dev/null
  fi

  # ── BASE ──────────────────────────────────────────────────
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

  # ── STAGING ───────────────────────────────────────────────
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

  # ── PROD ──────────────────────────────────────────────────
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

  echo -e "${GREEN}✓ Environment created at: $BASE_DIR${RESET}"

  print_section "Directory Structure"
  echo ""
  echo -e "  ${CYAN}$BASE_DIR/${RESET}"
  echo -e "  ├── base/"
  echo -e "  │   ├── kustomization.yaml"
  echo -e "  │   └── ${YELLOW}api-gateway.yaml${RESET}     ← ${RED}Remove ConfigMap${RESET}, ${GREEN}Add HPA${RESET}"
  echo -e "  ├── staging/"
  echo -e "  │   ├── kustomization.yaml"
  echo -e "  │   └── ${YELLOW}api-gateway.yaml${RESET}     ← ${RED}Remove ConfigMap block${RESET}"
  echo -e "  └── prod/"
  echo -e "      ├── kustomization.yaml"
  echo -e "      └── ${YELLOW}api-gateway.yaml${RESET}     ← ${RED}Remove ConfigMap block${RESET}, ${GREEN}Add HPA patch maxReplicas: 6${RESET}"

  print_section "Your Tasks"
  echo ""
  echo -e "${BOLD}1. Edit base/api-gateway.yaml${RESET}"
  print_cmd "vim $BASE_DIR/base/api-gateway.yaml"
  echo -e "   ${RED}▸ Remove:${RESET} entire ConfigMap block (apiVersion: v1 / kind: ConfigMap)"
  echo -e "   ${GREEN}▸ Add:${RESET} HPA block below:"
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

  echo -e "${BOLD}2. Edit staging/api-gateway.yaml${RESET}"
  print_cmd "vim $BASE_DIR/staging/api-gateway.yaml"
  echo -e "   ${RED}▸ Remove:${RESET} ConfigMap block (keep only Deployment patch)"
  echo ""
  echo -e "   Result should look like:"
  cat <<'STGYAML'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: staging
STGYAML

  echo ""
  echo -e "${BOLD}3. Edit prod/api-gateway.yaml${RESET}"
  print_cmd "vim $BASE_DIR/prod/api-gateway.yaml"
  echo -e "   ${RED}▸ Remove:${RESET} ConfigMap block"
  echo -e "   ${GREEN}▸ Add:${RESET} HPA patch with maxReplicas: 6"
  echo ""
  echo -e "   Result should look like:"
  cat <<'PRODYAML'
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: prod
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway
spec:
  maxReplicas: 6
PRODYAML

  echo ""
  echo -e "${BOLD}4. After edits — run validate:${RESET}"
  print_cmd "bash $0 validate"
  echo ""
  echo -e "${BOLD}5. Apply to cluster:${RESET}"
  print_cmd "bash $0 apply"
}

# ══════════════════════════════════════════════════════════════
# VALIDATE
# ══════════════════════════════════════════════════════════════
cmd_validate() {
  print_header "Q5 | Validating Your Changes"

  local STAGING_BUILD PROD_BUILD
  STAGING_BUILD=$(kubectl kustomize "$BASE_DIR/staging" 2>&1)
  PROD_BUILD=$(kubectl kustomize "$BASE_DIR/prod" 2>&1)

  # ── 1. Kustomize builds without error ─────────────────────
  print_section "1. Kustomize build (no errors)"

  if kubectl kustomize "$BASE_DIR/staging" &>/dev/null; then
    print_pass "staging kustomize build succeeds"
    ((PASS_COUNT++))
  else
    print_fail "staging kustomize build FAILED"
    echo -e "         ${RED}Error:${RESET} $STAGING_BUILD"
    ((FAIL_COUNT++))
  fi

  if kubectl kustomize "$BASE_DIR/prod" &>/dev/null; then
    print_pass "prod kustomize build succeeds"
    ((PASS_COUNT++))
  else
    print_fail "prod kustomize build FAILED"
    echo -e "         ${RED}Error:${RESET} $PROD_BUILD"
    ((FAIL_COUNT++))
  fi

  # ── 2. ConfigMap removed from base ────────────────────────
  print_section "2. ConfigMap removed from base"

  check_absent \
    "ConfigMap NOT in base/api-gateway.yaml" \
    "grep -c 'kind: ConfigMap' $BASE_DIR/base/api-gateway.yaml" \
    "1"

  check_absent \
    "horizontal-scaling-config NOT in staging build output" \
    "echo '$STAGING_BUILD'" \
    "horizontal-scaling-config"

  check_absent \
    "horizontal-scaling-config NOT in prod build output" \
    "echo '$PROD_BUILD'" \
    "horizontal-scaling-config"

  # ── 3. HPA in base ────────────────────────────────────────
  print_section "3. HPA added in base"

  check_output \
    "HPA kind present in base/api-gateway.yaml" \
    "cat $BASE_DIR/base/api-gateway.yaml" \
    "kind: HorizontalPodAutoscaler"

  check_output \
    "HPA minReplicas=2 in base" \
    "cat $BASE_DIR/base/api-gateway.yaml" \
    "minReplicas: 2"

  check_output \
    "HPA maxReplicas=4 in base" \
    "cat $BASE_DIR/base/api-gateway.yaml" \
    "maxReplicas: 4"

  check_output \
    "HPA cpu averageUtilization=50 in base" \
    "cat $BASE_DIR/base/api-gateway.yaml" \
    "averageUtilization: 50"

  check_output \
    "HPA scaleTargetRef points to api-gateway Deployment" \
    "cat $BASE_DIR/base/api-gateway.yaml" \
    "name: api-gateway"

  # ── 4. Staging build — HPA maxReplicas=4 ─────────────────
  print_section "4. Staging build — HPA maxReplicas=4"

  check_output \
    "staging build contains HPA" \
    "echo '$STAGING_BUILD'" \
    "HorizontalPodAutoscaler"

  check_output \
    "staging build maxReplicas=4" \
    "echo '$STAGING_BUILD'" \
    "maxReplicas: 4"

  check_output \
    "staging namespace = api-gateway-staging" \
    "echo '$STAGING_BUILD'" \
    "namespace: api-gateway-staging"

  # ── 5. Prod build — HPA maxReplicas=6 ────────────────────
  print_section "5. Prod build — HPA maxReplicas=6"

  check_output \
    "prod build contains HPA" \
    "echo '$PROD_BUILD'" \
    "HorizontalPodAutoscaler"

  check_output \
    "prod build maxReplicas=6" \
    "echo '$PROD_BUILD'" \
    "maxReplicas: 6"

  check_output \
    "prod namespace = api-gateway-prod" \
    "echo '$PROD_BUILD'" \
    "namespace: api-gateway-prod"

  # ── 6. Staging patch — no ConfigMap ──────────────────────
  print_section "6. Overlay patches clean (no ConfigMap)"

  check_absent \
    "staging/api-gateway.yaml has NO ConfigMap block" \
    "cat $BASE_DIR/staging/api-gateway.yaml" \
    "kind: ConfigMap"

  check_absent \
    "prod/api-gateway.yaml has NO ConfigMap block" \
    "cat $BASE_DIR/prod/api-gateway.yaml" \
    "kind: ConfigMap"

  # ── 7. Cluster state (if kubectl connected) ───────────────
  print_section "7. Cluster state (live)"

  if kubectl cluster-info &>/dev/null; then
    print_info "Cluster connected — checking live objects"

    if kubectl -n api-gateway-staging get hpa api-gateway &>/dev/null; then
      local stg_max; stg_max=$(kubectl -n api-gateway-staging get hpa api-gateway -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
      if [[ "$stg_max" == "4" ]]; then
        print_pass "staging HPA maxReplicas=4 (live)"
        ((PASS_COUNT++))
      else
        print_fail "staging HPA maxReplicas=$stg_max (expected 4)"
        ((FAIL_COUNT++))
      fi
    else
      print_warn "staging HPA not found — run: bash $0 apply"
    fi

    if kubectl -n api-gateway-prod get hpa api-gateway &>/dev/null; then
      local prod_max; prod_max=$(kubectl -n api-gateway-prod get hpa api-gateway -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
      if [[ "$prod_max" == "6" ]]; then
        print_pass "prod HPA maxReplicas=6 (live)"
        ((PASS_COUNT++))
      else
        print_fail "prod HPA maxReplicas=$prod_max (expected 6)"
        ((FAIL_COUNT++))
      fi
    else
      print_warn "prod HPA not found — run: bash $0 apply"
    fi

    if kubectl -n api-gateway-staging get cm horizontal-scaling-config &>/dev/null; then
      print_fail "ConfigMap still EXISTS in api-gateway-staging — delete it!"
      print_cmd "kubectl -n api-gateway-staging delete cm horizontal-scaling-config"
      ((FAIL_COUNT++))
    else
      print_pass "ConfigMap absent in api-gateway-staging (live)"
      ((PASS_COUNT++))
    fi

    if kubectl -n api-gateway-prod get cm horizontal-scaling-config &>/dev/null; then
      print_fail "ConfigMap still EXISTS in api-gateway-prod — delete it!"
      print_cmd "kubectl -n api-gateway-prod delete cm horizontal-scaling-config"
      ((FAIL_COUNT++))
    else
      print_pass "ConfigMap absent in api-gateway-prod (live)"
      ((PASS_COUNT++))
    fi

  else
    print_warn "No cluster connection — skipping live checks (offline validation only)"
  fi

  # ── Summary ───────────────────────────────────────────────
  echo ""
  divider
  local TOTAL=$((PASS_COUNT + FAIL_COUNT))
  if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "\n  ${GREEN}${BOLD}ALL CHECKS PASSED ✓  ($PASS_COUNT/$TOTAL)${RESET}\n"
  else
    echo -e "\n  ${RED}${BOLD}$FAIL_COUNT FAILED / $PASS_COUNT PASSED  (Total: $TOTAL)${RESET}\n"
    echo -e "  ${YELLOW}Fix the above failures then re-run:${RESET}"
    print_cmd "bash $0 validate"
  fi
  divider
  echo ""
}

# ══════════════════════════════════════════════════════════════
# APPLY
# ══════════════════════════════════════════════════════════════
cmd_apply() {
  print_header "Q5 | Applying to Cluster"

  if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}kubectl not found — cannot apply${RESET}"; exit 1
  fi

  print_section "Applying staging"
  kubectl kustomize "$BASE_DIR/staging" | kubectl apply -f -

  print_section "Applying prod"
  kubectl kustomize "$BASE_DIR/prod" | kubectl apply -f -

  print_section "Deleting old ConfigMaps (Kustomize never auto-deletes)"
  kubectl -n api-gateway-staging delete cm horizontal-scaling-config --ignore-not-found
  kubectl -n api-gateway-prod    delete cm horizontal-scaling-config --ignore-not-found

  print_section "Live status"
  echo ""
  kubectl -n api-gateway-staging get hpa,deploy 2>/dev/null || true
  echo ""
  kubectl -n api-gateway-prod    get hpa,deploy 2>/dev/null || true
  echo ""
  echo -e "${CYAN}Hint:${RESET} staging maxReplicas=4 | prod maxReplicas=6"
  echo -e "${CYAN}Hint:${RESET} Run '${BOLD}bash $0 validate${RESET}' to confirm everything"
}

# ══════════════════════════════════════════════════════════════
# CLEAN
# ══════════════════════════════════════════════════════════════
cmd_clean() {
  print_header "Q5 | Cleaning Up"
  if command -v kubectl &>/dev/null; then
    kubectl delete ns api-gateway-staging api-gateway-prod --ignore-not-found
  fi
  rm -rf "$BASE_DIR"
  echo -e "${GREEN}✓ Cleaned${RESET}"
}

# ══════════════════════════════════════════════════════════════
# SHOW ANSWER (for reference)
# ══════════════════════════════════════════════════════════════
cmd_answer() {
  print_header "Q5 | Expected Final File Contents"

  print_section "base/api-gateway.yaml (ConfigMap removed, HPA added)"
  cat <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-gateway
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
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
EOF

  print_section "staging/api-gateway.yaml (ConfigMap removed)"
  cat <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: staging
EOF

  print_section "prod/api-gateway.yaml (ConfigMap removed, HPA maxReplicas: 6)"
  cat <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  labels:
    env: prod
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway
spec:
  maxReplicas: 6
EOF
}

# ══════════════════════════════════════════════════════════════
# ROUTER
# ══════════════════════════════════════════════════════════════
case "${1:-help}" in
  setup)    cmd_setup ;;
  validate) cmd_validate ;;
  apply)    cmd_apply ;;
  clean)    cmd_clean ;;
  answer)   cmd_answer ;;
  *)
    print_header "Q5 | Kustomize HPA Autoscaler"
    echo -e "  Usage: ${BOLD}bash $0 <command>${RESET}"
    echo ""
    echo -e "  ${CYAN}setup${RESET}     Create the exercise environment"
    echo -e "  ${CYAN}validate${RESET}  Check your changes (offline + live)"
    echo -e "  ${CYAN}apply${RESET}     Apply to cluster + delete old ConfigMaps"
    echo -e "  ${CYAN}clean${RESET}     Delete namespaces + files"
    echo -e "  ${CYAN}answer${RESET}    Show expected final file contents"
    echo ""
    ;;
esac
