#!/bin/bash
# ============================================================
#  CKA Practice Lab — Validation Script
#  Style: killer.sh automated scoring
#  Usage: bash validate.sh [q1|q2|q3|...|all]
# ============================================================

# ── colours & helpers ────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
PASS="${GREEN}[PASS]${RESET}"; FAIL="${RED}[FAIL]${RESET}"; SKIP="${YELLOW}[SKIP]${RESET}"

TOTAL=0; PASSED=0; FAILED=0

_pass() { echo -e "  ${PASS} $1"; ((PASSED++)); ((TOTAL++)); }
_fail() { echo -e "  ${FAIL} $1"; ((FAILED++)); ((TOTAL++)); }
_skip() { echo -e "  ${SKIP} $1 ${YELLOW}(cannot verify from this node)${RESET}"; ((TOTAL++)); }
_info() { echo -e "        ${CYAN}↳ $1${RESET}"; }

header() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  $1${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

check_cmd() { command -v "$1" &>/dev/null; }
kc() { kubectl "$@" 2>/dev/null; }

# ── Q1 — Kubeconfig Extraction ───────────────────────────────
validate_q1() {
  header "Q1 | Kubeconfig Extraction  [node: cka9412]"
  local DIR="/opt/course/1"
  local KC="$DIR/kubeconfig"

  # contexts file
  if [[ -f "$DIR/contexts" ]]; then
    local lines; lines=$(wc -l < "$DIR/contexts")
    local content; content=$(cat "$DIR/contexts")
    if echo "$content" | grep -q "cluster-admin" && \
       echo "$content" | grep -q "cluster-w100"  && \
       echo "$content" | grep -q "cluster-w200"; then
      _pass "contexts file exists and contains all 3 context names"
      _info "$(cat "$DIR/contexts" | tr '\n' ' ')"
    else
      _fail "contexts file missing one or more expected names (cluster-admin, cluster-w100, cluster-w200)"
      _info "actual content: $content"
    fi

    if [[ "$lines" -eq 3 ]]; then
      _pass "contexts file has exactly 3 lines (one per line)"
    else
      _fail "contexts file should have 3 lines, got: $lines"
    fi
  else
    _fail "contexts file not found at $DIR/contexts"
    _fail "contexts line count check skipped"
  fi

  # current-context file
  if [[ -f "$DIR/current-context" ]]; then
    local cc; cc=$(cat "$DIR/current-context" | tr -d '[:space:]')
    if [[ "$cc" == "cluster-w200" ]]; then
      _pass "current-context = cluster-w200"
    else
      _fail "current-context expected 'cluster-w200', got '$cc'"
    fi
  else
    _fail "current-context file not found at $DIR/current-context"
  fi

  # cert file
  if [[ -f "$DIR/cert" ]]; then
    local head; head=$(head -1 "$DIR/cert")
    if [[ "$head" == "-----BEGIN CERTIFICATE-----" ]]; then
      _pass "cert file is PEM-decoded (starts with -----BEGIN CERTIFICATE-----)"
    else
      _fail "cert file does not look PEM-decoded. First line: $head"
    fi

    if check_cmd openssl; then
      local subj; subj=$(openssl x509 -in "$DIR/cert" -noout -subject 2>/dev/null)
      if echo "$subj" | grep -qi "account-0027"; then
        _pass "cert subject contains 'account-0027' — correct user"
        _info "$subj"
      else
        _fail "cert subject does not contain 'account-0027'"
        _info "actual subject: $subj"
      fi
    else
      _skip "openssl not available — skipping cert subject check"
    fi
  else
    _fail "cert file not found at $DIR/cert"
    _fail "cert subject check skipped"
  fi
}

# ── Q2 — MinIO Operator ──────────────────────────────────────
validate_q2() {
  header "Q2 | MinIO Operator + Tenant CRD  [node: cka7968]"
  local YAML="/opt/course/2/minio-tenant.yaml"

  # namespace
  local ns_phase; ns_phase=$(kc get ns minio -o jsonpath='{.status.phase}')
  if [[ "$ns_phase" == "Active" ]]; then
    _pass "Namespace minio exists and is Active"
  else
    _fail "Namespace minio not found or not Active (got: $ns_phase)"
  fi

  # helm release
  if check_cmd helm; then
    local rel; rel=$(helm -n minio ls --short 2>/dev/null | grep "minio-operator")
    if [[ -n "$rel" ]]; then
      _pass "Helm release 'minio-operator' found in namespace minio"
    else
      _fail "Helm release 'minio-operator' not found in namespace minio"
    fi

    local chart; chart=$(helm -n minio ls 2>/dev/null | grep minio-operator | awk '{print $9}')
    if echo "$chart" | grep -qi "operator"; then
      _pass "Helm release is based on the operator chart ($chart)"
    else
      _fail "Helm release chart name doesn't look right: $chart"
    fi
  else
    _skip "helm not available — skipping release checks"
    _skip "helm chart name check skipped"
  fi

  # CRD installed
  local crd; crd=$(kc get crd tenants.minio.min.io --no-headers 2>/dev/null | awk '{print $1}')
  if [[ "$crd" == "tenants.minio.min.io" ]]; then
    _pass "CRD tenants.minio.min.io exists (installed by Helm chart)"
  else
    _fail "CRD tenants.minio.min.io not found — did the Helm install succeed?"
  fi

  # YAML has enableSFTP
  if [[ -f "$YAML" ]]; then
    if grep -q "enableSFTP: true" "$YAML"; then
      _pass "minio-tenant.yaml contains 'enableSFTP: true'"
    else
      _fail "minio-tenant.yaml does NOT contain 'enableSFTP: true'"
      _info "grep result: $(grep enableSFTP "$YAML" 2>/dev/null || echo 'not found')"
    fi

    # indentation — must be under spec.features
    if grep -A1 "features:" "$YAML" 2>/dev/null | grep -q "enableSFTP\|bucketDNS"; then
      _pass "enableSFTP appears to be under spec.features block"
    else
      _fail "enableSFTP may not be correctly placed under spec.features"
    fi
  else
    _fail "minio-tenant.yaml not found at $YAML"
    _fail "enableSFTP indentation check skipped"
  fi

  # live resource
  local sftp; sftp=$(kc -n minio get tenant tenant -o jsonpath='{.spec.features.enableSFTP}' 2>/dev/null)
  if [[ "$sftp" == "true" ]]; then
    _pass "Live Tenant resource has spec.features.enableSFTP=true"
  else
    _fail "Live Tenant resource missing or spec.features.enableSFTP != true (got: '$sftp')"
  fi

  # tenant resource exists
  local t; t=$(kc -n minio get tenant tenant --no-headers 2>/dev/null | awk '{print $1}')
  if [[ "$t" == "tenant" ]]; then
    _pass "Tenant resource named 'tenant' exists in namespace minio"
  else
    _fail "Tenant resource 'tenant' not found in namespace minio"
  fi
}

# ── Q3 — Scale StatefulSet ───────────────────────────────────
validate_q3() {
  header "Q3 | Scale StatefulSet  [node: cka3962]"

  local ready; ready=$(kc -n project-h800 get sts o3db -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  local desired; desired=$(kc -n project-h800 get sts o3db -o jsonpath='{.spec.replicas}' 2>/dev/null)

  if [[ "$desired" == "1" ]]; then
    _pass "StatefulSet o3db spec.replicas = 1"
  else
    _fail "StatefulSet o3db spec.replicas expected 1, got '$desired'"
  fi

  if [[ "$ready" == "1" ]]; then
    _pass "StatefulSet o3db has 1 ready replica"
  else
    _fail "StatefulSet o3db readyReplicas expected 1, got '$ready'"
  fi

  local pods; pods=$(kc -n project-h800 get pod --no-headers 2>/dev/null | grep "^o3db-" | wc -l)
  if [[ "$pods" -eq 1 ]]; then
    _pass "Exactly 1 Pod prefixed with 'o3db-' running in project-h800"
    _info "Pod: $(kc -n project-h800 get pod --no-headers | grep '^o3db-' | awk '{print $1, $3}')"
  else
    _fail "Expected 1 o3db Pod, found $pods"
  fi

  # confirm o3db-1 is gone (scaled down from highest index)
  local pod1; pod1=$(kc -n project-h800 get pod o3db-1 --no-headers 2>/dev/null | awk '{print $1}')
  if [[ -z "$pod1" ]]; then
    _pass "o3db-1 has been terminated (highest-index Pod removed first)"
  else
    _fail "o3db-1 still exists — StatefulSet may not have scaled down yet"
  fi
}

# ── Q4 — Pods First Terminated ──────────────────────────────
validate_q4() {
  header "Q4 | Find Pods First to be Terminated  [node: cka2556]"
  local FILE="/opt/course/4/pods-terminated-first.txt"

  if [[ -f "$FILE" ]]; then
    _pass "Output file exists at $FILE"
    local count; count=$(wc -l < "$FILE")
    _info "Lines in file: $count"

    # All pods in the file should be from the c13-3cc-runner-heavy deployment
    local bad=0
    while IFS= read -r pod; do
      [[ -z "$pod" ]] && continue
      if ! echo "$pod" | grep -q "c13-3cc-runner-heavy"; then
        _fail "Unexpected pod in list: '$pod' (expected only c13-3cc-runner-heavy-* pods)"
        bad=1
      fi
    done < "$FILE"
    [[ "$bad" -eq 0 ]] && _pass "All listed pods are from c13-3cc-runner-heavy deployment (BestEffort QoS)"

    # Cross-check with live cluster — QoS BestEffort pods
    local live_best; live_best=$(kc get pods -n project-c13 -o jsonpath="{range .items[*]}{.metadata.name} {.status.qosClass}{'\n'}" 2>/dev/null | grep BestEffort | awk '{print $1}')
    if [[ -n "$live_best" ]]; then
      local match=1
      while IFS= read -r lp; do
        if ! grep -q "$lp" "$FILE"; then
          _fail "Live BestEffort Pod '$lp' not listed in your output file"
          match=0
        fi
      done <<< "$live_best"
      [[ "$match" -eq 1 ]] && _pass "All live BestEffort QoS pods are captured in the file"
    else
      _skip "Could not query live project-c13 pods (wrong node or cluster)"
    fi
  else
    _fail "Output file not found: $FILE"
    _fail "Pod content check skipped"
    _fail "Live QoS cross-check skipped"
  fi
}

# ── Q5 — Kustomize HPA ──────────────────────────────────────
validate_q5() {
  header "Q5 | Kustomize HPA Autoscaler  [node: cka5774]"

  # staging HPA
  local stg_min; stg_min=$(kc -n api-gateway-staging get hpa api-gateway -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
  local stg_max; stg_max=$(kc -n api-gateway-staging get hpa api-gateway -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
  local stg_cpu; stg_cpu=$(kc -n api-gateway-staging get hpa api-gateway -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)

  if [[ "$stg_min" == "2" ]]; then
    _pass "HPA api-gateway (staging): minReplicas = 2"
  else
    _fail "HPA api-gateway (staging): minReplicas expected 2, got '$stg_min'"
  fi
  if [[ "$stg_max" == "4" ]]; then
    _pass "HPA api-gateway (staging): maxReplicas = 4"
  else
    _fail "HPA api-gateway (staging): maxReplicas expected 4, got '$stg_max'"
  fi
  if [[ "$stg_cpu" == "50" ]]; then
    _pass "HPA api-gateway (staging): averageUtilization = 50%"
  else
    _fail "HPA api-gateway (staging): averageUtilization expected 50, got '$stg_cpu'"
  fi

  # prod HPA
  local prd_max; prd_max=$(kc -n api-gateway-prod get hpa api-gateway -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
  local prd_min; prd_min=$(kc -n api-gateway-prod get hpa api-gateway -o jsonpath='{.spec.minReplicas}' 2>/dev/null)

  if [[ "$prd_min" == "2" ]]; then
    _pass "HPA api-gateway (prod): minReplicas = 2"
  else
    _fail "HPA api-gateway (prod): minReplicas expected 2, got '$prd_min'"
  fi
  if [[ "$prd_max" == "6" ]]; then
    _pass "HPA api-gateway (prod): maxReplicas = 6"
  else
    _fail "HPA api-gateway (prod): maxReplicas expected 6, got '$prd_max'"
  fi

  # ConfigMap removed
  local cm_stg; cm_stg=$(kc -n api-gateway-staging get cm horizontal-scaling-config --no-headers 2>/dev/null | awk '{print $1}')
  local cm_prd; cm_prd=$(kc -n api-gateway-prod get cm horizontal-scaling-config --no-headers 2>/dev/null | awk '{print $1}')

  if [[ -z "$cm_stg" ]]; then
    _pass "ConfigMap horizontal-scaling-config removed from api-gateway-staging"
  else
    _fail "ConfigMap horizontal-scaling-config still exists in api-gateway-staging"
  fi
  if [[ -z "$cm_prd" ]]; then
    _pass "ConfigMap horizontal-scaling-config removed from api-gateway-prod"
  else
    _fail "ConfigMap horizontal-scaling-config still exists in api-gateway-prod"
  fi
}

# ── Q6 — PV / PVC / Deployment ──────────────────────────────
validate_q6() {
  header "Q6 | Storage PV, PVC, Pod Volume  [node: cka7968]"

  # PV
  local pv_cap; pv_cap=$(kc get pv safari-pv -o jsonpath='{.spec.capacity.storage}' 2>/dev/null)
  local pv_mode; pv_mode=$(kc get pv safari-pv -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)
  local pv_path; pv_path=$(kc get pv safari-pv -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)
  local pv_sc; pv_sc=$(kc get pv safari-pv -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
  local pv_status; pv_status=$(kc get pv safari-pv -o jsonpath='{.status.phase}' 2>/dev/null)

  [[ "$pv_cap" == "2Gi" ]]            && _pass "PV safari-pv: capacity = 2Gi"       || _fail "PV capacity expected 2Gi, got '$pv_cap'"
  [[ "$pv_mode" == "ReadWriteOnce" ]] && _pass "PV safari-pv: accessMode = ReadWriteOnce" || _fail "PV accessMode expected ReadWriteOnce, got '$pv_mode'"
  [[ "$pv_path" == "/Volumes/Data" ]] && _pass "PV safari-pv: hostPath = /Volumes/Data"   || _fail "PV hostPath expected /Volumes/Data, got '$pv_path'"
  [[ -z "$pv_sc" ]]                   && _pass "PV safari-pv: no storageClassName set"    || _fail "PV storageClassName should be empty, got '$pv_sc'"
  [[ "$pv_status" == "Bound" ]]       && _pass "PV safari-pv: status = Bound"             || _fail "PV status expected Bound, got '$pv_status'"

  # PVC
  local pvc_cap; pvc_cap=$(kc -n project-t230 get pvc safari-pvc -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)
  local pvc_mode; pvc_mode=$(kc -n project-t230 get pvc safari-pvc -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)
  local pvc_sc; pvc_sc=$(kc -n project-t230 get pvc safari-pvc -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
  local pvc_status; pvc_status=$(kc -n project-t230 get pvc safari-pvc -o jsonpath='{.status.phase}' 2>/dev/null)
  local pvc_vol; pvc_vol=$(kc -n project-t230 get pvc safari-pvc -o jsonpath='{.spec.volumeName}' 2>/dev/null)

  [[ "$pvc_cap" == "2Gi" ]]            && _pass "PVC safari-pvc: requests.storage = 2Gi"   || _fail "PVC storage request expected 2Gi, got '$pvc_cap'"
  [[ "$pvc_mode" == "ReadWriteOnce" ]] && _pass "PVC safari-pvc: accessMode = ReadWriteOnce" || _fail "PVC accessMode expected ReadWriteOnce, got '$pvc_mode'"
  [[ -z "$pvc_sc" ]]                   && _pass "PVC safari-pvc: no storageClassName set"    || _fail "PVC storageClassName should be empty, got '$pvc_sc'"
  [[ "$pvc_status" == "Bound" ]]       && _pass "PVC safari-pvc: status = Bound"             || _fail "PVC status expected Bound, got '$pvc_status'"
  [[ "$pvc_vol" == "safari-pv" ]]      && _pass "PVC safari-pvc: bound to PV safari-pv"      || _fail "PVC bound PV expected safari-pv, got '$pvc_vol'"

  # Deployment
  local dep_img; dep_img=$(kc -n project-t230 get deploy safari -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  local dep_mount; dep_mount=$(kc -n project-t230 get deploy safari -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)
  local dep_pvc; dep_pvc=$(kc -n project-t230 get deploy safari -o jsonpath='{.spec.template.spec.volumes[0].persistentVolumeClaim.claimName}' 2>/dev/null)

  [[ "$dep_img" == "httpd:2-alpine" ]]    && _pass "Deployment safari: image = httpd:2-alpine"             || _fail "Deployment image expected httpd:2-alpine, got '$dep_img'"
  [[ "$dep_mount" == "/tmp/safari-data" ]] && _pass "Deployment safari: volumeMount at /tmp/safari-data"   || _fail "Deployment mountPath expected /tmp/safari-data, got '$dep_mount'"
  [[ "$dep_pvc" == "safari-pvc" ]]         && _pass "Deployment safari: uses PVC safari-pvc"               || _fail "Deployment PVC claimName expected safari-pvc, got '$dep_pvc'"
}

# ── Q7 — Top Scripts ─────────────────────────────────────────
validate_q7() {
  header "Q7 | Node and Pod Resource Usage Scripts  [node: cka5774]"

  local node_sh="/opt/course/7/node.sh"
  local pod_sh="/opt/course/7/pod.sh"

  if [[ -f "$node_sh" ]]; then
    _pass "node.sh exists at $node_sh"
    if grep -q "kubectl top node" "$node_sh"; then
      _pass "node.sh contains 'kubectl top node' (full command, no alias)"
    else
      _fail "node.sh should contain 'kubectl top node', content: $(cat "$node_sh")"
    fi
  else
    _fail "node.sh not found at $node_sh"
    _fail "node.sh content check skipped"
  fi

  if [[ -f "$pod_sh" ]]; then
    _pass "pod.sh exists at $pod_sh"
    if grep -q "kubectl top pod" "$pod_sh" && grep -q "\-\-containers" "$pod_sh"; then
      _pass "pod.sh contains 'kubectl top pod --containers=true'"
    else
      _fail "pod.sh should contain 'kubectl top pod --containers=true', content: $(cat "$pod_sh")"
    fi
  else
    _fail "pod.sh not found at $pod_sh"
    _fail "pod.sh content check skipped"
  fi
}

# ── Q8 — Node Join & Version ─────────────────────────────────
validate_q8() {
  header "Q8 | Update K8s Version + Join Node  [node: cka3962]"

  local cp_ver; cp_ver=$(kc get node cka3962 -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
  local wk_ver; wk_ver=$(kc get node cka3962-node1 -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
  local wk_ready; wk_ready=$(kc get node cka3962-node1 -o jsonpath='{.status.conditions[-1].type}' 2>/dev/null)

  if [[ -n "$cp_ver" ]]; then
    _pass "Controlplane node cka3962 found, version: $cp_ver"
  else
    _fail "Could not get controlplane node version (wrong node?)"
  fi

  if [[ -n "$wk_ver" ]]; then
    _pass "Worker node cka3962-node1 joined the cluster, version: $wk_ver"
  else
    _fail "Worker node cka3962-node1 not found in cluster"
  fi

  if [[ "$cp_ver" == "$wk_ver" ]]; then
    _pass "Both nodes run the same Kubernetes version ($cp_ver)"
  else
    _fail "Version mismatch: controlplane=$cp_ver, worker=$wk_ver"
  fi

  if [[ "$wk_ready" == "Ready" ]]; then
    _pass "cka3962-node1 status = Ready"
  else
    _fail "cka3962-node1 is not Ready (status: $wk_ready)"
  fi
}

# ── Q9 — Contact K8s API from Pod ───────────────────────────
validate_q9() {
  header "Q9 | Contact K8s API from inside Pod  [node: cka9412]"
  local RESULT="/opt/course/9/result.json"

  # pod exists
  local pod_phase; pod_phase=$(kc -n project-swan get pod api-contact -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$pod_phase" == "Running" ]]; then
    _pass "Pod api-contact is Running in namespace project-swan"
  else
    _fail "Pod api-contact not Running in project-swan (phase: $pod_phase)"
  fi

  local pod_sa; pod_sa=$(kc -n project-swan get pod api-contact -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
  if [[ "$pod_sa" == "secret-reader" ]]; then
    _pass "Pod api-contact uses ServiceAccount secret-reader"
  else
    _fail "Pod serviceAccountName expected 'secret-reader', got '$pod_sa'"
  fi

  local pod_img; pod_img=$(kc -n project-swan get pod api-contact -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
  if [[ "$pod_img" == "nginx:1-alpine" ]]; then
    _pass "Pod api-contact uses image nginx:1-alpine"
  else
    _fail "Pod image expected 'nginx:1-alpine', got '$pod_img'"
  fi

  # result file
  if [[ -f "$RESULT" ]]; then
    _pass "Result file exists at $RESULT"
    if grep -q '"kind"' "$RESULT" && grep -q '"SecretList"\|"Secret"' "$RESULT"; then
      _pass "Result file contains Secret/SecretList JSON response from K8s API"
    else
      _fail "Result file does not look like a K8s API SecretList response"
      _info "First line: $(head -1 "$RESULT")"
    fi
    if grep -qi '"apiVersion"' "$RESULT"; then
      _pass "Result file contains apiVersion field (valid K8s API response)"
    else
      _fail "Result file missing apiVersion — may not be a valid K8s API response"
    fi
  else
    _fail "Result file not found at $RESULT"
    _fail "Result content checks skipped"
    _fail "apiVersion check skipped"
  fi
}

# ── Q10 — RBAC SA / Role / RoleBinding ──────────────────────
validate_q10() {
  header "Q10 | RBAC ServiceAccount Role RoleBinding  [node: cka3962]"

  # SA
  local sa; sa=$(kc -n project-hamster get sa processor -o jsonpath='{.metadata.name}' 2>/dev/null)
  [[ "$sa" == "processor" ]] && _pass "ServiceAccount 'processor' exists in project-hamster" || _fail "ServiceAccount 'processor' not found in project-hamster"

  # Role
  local role_res; role_res=$(kc -n project-hamster get role processor -o jsonpath='{.rules[0].resources}' 2>/dev/null)
  local role_verb; role_verb=$(kc -n project-hamster get role processor -o jsonpath='{.rules[0].verbs}' 2>/dev/null)

  [[ -n "$role_res" ]] && _pass "Role 'processor' exists in project-hamster" || _fail "Role 'processor' not found in project-hamster"

  if echo "$role_res" | grep -q "secrets" && echo "$role_res" | grep -q "configmaps"; then
    _pass "Role 'processor' covers both secrets and configmaps"
  else
    _fail "Role 'processor' resources should include secrets and configmaps, got: $role_res"
  fi

  if echo "$role_verb" | grep -q "create"; then
    _pass "Role 'processor' has verb 'create'"
  else
    _fail "Role 'processor' should have verb 'create', got: $role_verb"
  fi

  # RoleBinding
  local rb_role; rb_role=$(kc -n project-hamster get rolebinding processor -o jsonpath='{.roleRef.name}' 2>/dev/null)
  local rb_sa; rb_sa=$(kc -n project-hamster get rolebinding processor -o jsonpath='{.subjects[0].name}' 2>/dev/null)
  local rb_ns; rb_ns=$(kc -n project-hamster get rolebinding processor -o jsonpath='{.subjects[0].namespace}' 2>/dev/null)

  [[ "$rb_role" == "processor" ]] && _pass "RoleBinding 'processor' references Role 'processor'" || _fail "RoleBinding roleRef expected 'processor', got '$rb_role'"
  [[ "$rb_sa" == "processor" ]]   && _pass "RoleBinding 'processor' references SA 'processor'"   || _fail "RoleBinding subject name expected 'processor', got '$rb_sa'"
  [[ "$rb_ns" == "project-hamster" ]] && _pass "RoleBinding subject namespace = project-hamster" || _fail "RoleBinding subject namespace expected project-hamster, got '$rb_ns'"

  # auth can-i
  local can_secret; can_secret=$(kc -n project-hamster auth can-i create secret --as system:serviceaccount:project-hamster:processor 2>/dev/null)
  local can_cm;     can_cm=$(kc -n project-hamster auth can-i create configmap --as system:serviceaccount:project-hamster:processor 2>/dev/null)
  local cannot_pod; cannot_pod=$(kc -n project-hamster auth can-i create pod --as system:serviceaccount:project-hamster:processor 2>/dev/null)
  local cannot_del; cannot_del=$(kc -n project-hamster auth can-i delete secret --as system:serviceaccount:project-hamster:processor 2>/dev/null)

  [[ "$can_secret" == "yes" ]]  && _pass "SA processor CAN create secrets"    || _fail "SA processor should be able to create secrets"
  [[ "$can_cm" == "yes" ]]      && _pass "SA processor CAN create configmaps" || _fail "SA processor should be able to create configmaps"
  [[ "$cannot_pod" == "no" ]]   && _pass "SA processor CANNOT create pods"    || _fail "SA processor should NOT be able to create pods"
  [[ "$cannot_del" == "no" ]]   && _pass "SA processor CANNOT delete secrets" || _fail "SA processor should NOT be able to delete secrets"
}

# ── Q11 — DaemonSet on all Nodes ────────────────────────────
validate_q11() {
  header "Q11 | DaemonSet on all Nodes  [node: cka2556]"

  local ds_img; ds_img=$(kc -n project-tiger get ds ds-important -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  local ds_cpu; ds_cpu=$(kc -n project-tiger get ds ds-important -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
  local ds_mem; ds_mem=$(kc -n project-tiger get ds ds-important -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null)
  local ds_lid; ds_lid=$(kc -n project-tiger get ds ds-important -o jsonpath='{.metadata.labels.id}' 2>/dev/null)
  local ds_luu; ds_luu=$(kc -n project-tiger get ds ds-important -o jsonpath='{.metadata.labels.uuid}' 2>/dev/null)
  local ds_desired; ds_desired=$(kc -n project-tiger get ds ds-important -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
  local ds_ready;   ds_ready=$(kc -n project-tiger get ds ds-important -o jsonpath='{.status.numberReady}' 2>/dev/null)
  local ds_tolkey;  ds_tolkey=$(kc -n project-tiger get ds ds-important -o jsonpath='{.spec.template.spec.tolerations[0].key}' 2>/dev/null)

  [[ "$ds_img" == "httpd:2-alpine" ]] && _pass "DaemonSet ds-important: image = httpd:2-alpine"              || _fail "DaemonSet image expected httpd:2-alpine, got '$ds_img'"
  [[ "$ds_cpu" == "10m" ]]            && _pass "DaemonSet ds-important: cpu request = 10m"                   || _fail "DaemonSet cpu request expected 10m, got '$ds_cpu'"
  [[ "$ds_mem" == "10Mi" ]]           && _pass "DaemonSet ds-important: memory request = 10Mi"               || _fail "DaemonSet memory request expected 10Mi, got '$ds_mem'"
  [[ "$ds_lid" == "ds-important" ]]   && _pass "DaemonSet ds-important: label id=ds-important"               || _fail "DaemonSet label id expected ds-important, got '$ds_lid'"
  [[ "$ds_luu" == "18426a0b-5f59-4e10-923f-c0e078e82462" ]] && _pass "DaemonSet ds-important: label uuid correct" || _fail "DaemonSet label uuid wrong, got '$ds_luu'"

  if echo "$ds_tolkey" | grep -q "control-plane"; then
    _pass "DaemonSet has toleration for node-role.kubernetes.io/control-plane (runs on all nodes)"
  else
    _fail "DaemonSet missing control-plane toleration — won't schedule on controlplane nodes"
    _info "toleration key found: '$ds_tolkey'"
  fi

  if [[ -n "$ds_desired" && "$ds_desired" == "$ds_ready" && "$ds_ready" -gt 0 ]]; then
    _pass "DaemonSet ds-important: all $ds_ready/$ds_desired scheduled pods are ready"
  else
    _fail "DaemonSet not fully ready: $ds_ready/$ds_desired ready"
  fi

  # verify pod labels match pod template
  local pod_lid; pod_lid=$(kc -n project-tiger get pod -l id=ds-important,uuid=18426a0b-5f59-4e10-923f-c0e078e82462 --no-headers 2>/dev/null | wc -l)
  if [[ "$pod_lid" -gt 0 ]]; then
    _pass "Pods with both required labels (id + uuid) exist in project-tiger"
  else
    _fail "No pods found with both labels id=ds-important and uuid=18426a0b-..."
  fi
}

# ── Q12 — Deployment one Pod per Node ───────────────────────
validate_q12() {
  header "Q12 | Deployment one Pod per Worker Node  [node: cka2556]"

  local dep_rep; dep_rep=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.spec.replicas}' 2>/dev/null)
  local dep_lid; dep_lid=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.metadata.labels.id}' 2>/dev/null)
  local c1_img; c1_img=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.spec.template.spec.containers[?(@.name=="container1")].image}' 2>/dev/null)
  local c2_img; c2_img=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.spec.template.spec.containers[?(@.name=="container2")].image}' 2>/dev/null)

  [[ "$dep_rep" == "3" ]]             && _pass "Deployment deploy-important: replicas = 3"             || _fail "Deployment replicas expected 3, got '$dep_rep'"
  [[ "$dep_lid" == "very-important" ]] && _pass "Deployment deploy-important: label id=very-important"  || _fail "Deployment label id expected very-important, got '$dep_lid'"
  [[ "$c1_img" == "nginx:1-alpine" ]] && _pass "Container container1: image = nginx:1-alpine"           || _fail "container1 image expected nginx:1-alpine, got '$c1_img'"
  [[ "$c2_img" == "google/pause" ]]   && _pass "Container container2: image = google/pause"             || _fail "container2 image expected google/pause, got '$c2_img'"

  # Anti-affinity or topology spread
  local has_aa; has_aa=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}' 2>/dev/null)
  local has_ts; has_ts=$(kc -n project-tiger get deploy deploy-important -o jsonpath='{.spec.template.spec.topologySpreadConstraints}' 2>/dev/null)

  if [[ -n "$has_aa" ]] || [[ -n "$has_ts" ]]; then
    _pass "Deployment uses podAntiAffinity or topologySpreadConstraints to spread pods"
  else
    _fail "Deployment missing podAntiAffinity or topologySpreadConstraints"
  fi

  # max 1 pod per node (2 running, 1 Pending)
  local running; running=$(kc -n project-tiger get pod -l id=very-important --no-headers 2>/dev/null | grep "Running" | wc -l)
  local pending; pending=$(kc -n project-tiger get pod -l id=very-important --no-headers 2>/dev/null | grep "Pending" | wc -l)

  if [[ "$running" -eq 2 && "$pending" -eq 1 ]]; then
    _pass "Exactly 2 Running + 1 Pending pod (one Pod per worker node enforced)"
  else
    _fail "Expected 2 Running + 1 Pending, got: Running=$running Pending=$pending"
  fi
}

# ── Q13 — Gateway API HTTPRoute ──────────────────────────────
validate_q13() {
  header "Q13 | Gateway API HTTPRoute  [node: cka7968]"

  local hr; hr=$(kc -n project-r500 get httproute traffic-director -o jsonpath='{.metadata.name}' 2>/dev/null)
  [[ "$hr" == "traffic-director" ]] && _pass "HTTPRoute 'traffic-director' exists in project-r500" || _fail "HTTPRoute 'traffic-director' not found in project-r500"

  # parentRef
  local parent; parent=$(kc -n project-r500 get httproute traffic-director -o jsonpath='{.spec.parentRefs[0].name}' 2>/dev/null)
  [[ "$parent" == "main" ]] && _pass "HTTPRoute references Gateway 'main'" || _fail "HTTPRoute parentRef should be 'main', got '$parent'"

  # hostname
  local hn; hn=$(kc -n project-r500 get httproute traffic-director -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null)
  [[ "$hn" == "r500.gateway" ]] && _pass "HTTPRoute hostname = r500.gateway" || _fail "HTTPRoute hostname expected r500.gateway, got '$hn'"

  # rules count — should have at least 4 (desktop, mobile, auto-mobile, auto-default)
  local rules; rules=$(kc -n project-r500 get httproute traffic-director -o jsonpath='{.spec.rules}' 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d))" 2>/dev/null)
  if [[ "$rules" -ge 4 ]]; then
    _pass "HTTPRoute has $rules rules (≥ 4 required for /desktop, /mobile, /auto×2)"
  else
    _fail "HTTPRoute has $rules rules, expected ≥ 4 (/desktop, /mobile, /auto mobile, /auto default)"
  fi

  # connectivity via curl
  if check_cmd curl && grep -q "r500.gateway" /etc/hosts 2>/dev/null; then
    local d; d=$(curl -s --max-time 3 r500.gateway:30080/desktop 2>/dev/null)
    local m; m=$(curl -s --max-time 3 r500.gateway:30080/mobile 2>/dev/null)
    local am; am=$(curl -s --max-time 3 -H "User-Agent: mobile" r500.gateway:30080/auto 2>/dev/null)
    local ad; ad=$(curl -s --max-time 3 r500.gateway:30080/auto 2>/dev/null)

    echo "$d" | grep -qi "desktop"          && _pass "curl /desktop → desktop backend responds"         || _fail "curl /desktop did not return desktop response: '$d'"
    echo "$m" | grep -qi "mobile"           && _pass "curl /mobile → mobile backend responds"           || _fail "curl /mobile did not return mobile response: '$m'"
    echo "$am" | grep -qi "mobile"          && _pass "curl /auto (User-Agent: mobile) → mobile backend" || _fail "curl /auto with mobile User-Agent got: '$am'"
    echo "$ad" | grep -qi "desktop"         && _pass "curl /auto (no User-Agent) → desktop backend"     || _fail "curl /auto without User-Agent got: '$ad'"
  else
    _skip "curl or r500.gateway /etc/hosts entry not available — skipping connectivity tests"
    _skip "/desktop response check skipped"
    _skip "/mobile response check skipped"
    _skip "/auto mobile header check skipped"
    _skip "/auto default check skipped"
  fi
}

# ── Q14 — Certificate Expiry ────────────────────────────────
validate_q14() {
  header "Q14 | Certificate Expiry  [node: cka9412]"
  local EXP_FILE="/opt/course/14/expiration"
  local RENEW_FILE="/opt/course/14/kubeadm-renew-certs.sh"

  if [[ -f "$EXP_FILE" ]]; then
    _pass "Expiration file exists at $EXP_FILE"
    local exp_content; exp_content=$(cat "$EXP_FILE")
    _info "Expiration content: $exp_content"

    # Verify matches openssl
    if check_cmd openssl && [[ -f /etc/kubernetes/pki/apiserver.crt ]]; then
      local real_exp; real_exp=$(openssl x509 -noout -enddate -in /etc/kubernetes/pki/apiserver.crt 2>/dev/null | sed 's/notAfter=//')
      if [[ "$exp_content" == "$real_exp" ]]; then
        _pass "Expiration date matches openssl output: $real_exp"
      else
        _fail "Expiration mismatch — file='$exp_content', openssl='$real_exp'"
      fi
    else
      _skip "openssl or /etc/kubernetes/pki/apiserver.crt not accessible — skipping cross-check"
    fi
  else
    _fail "Expiration file not found at $EXP_FILE"
    _skip "openssl cross-check skipped"
  fi

  if [[ -f "$RENEW_FILE" ]]; then
    _pass "kubeadm-renew-certs.sh exists at $RENEW_FILE"
    if grep -q "kubeadm certs renew apiserver" "$RENEW_FILE"; then
      _pass "kubeadm-renew-certs.sh contains 'kubeadm certs renew apiserver'"
    else
      _fail "kubeadm-renew-certs.sh content wrong: $(cat "$RENEW_FILE")"
    fi
  else
    _fail "kubeadm-renew-certs.sh not found at $RENEW_FILE"
    _fail "renew command content check skipped"
  fi
}

# ── Q15 — NetworkPolicy ──────────────────────────────────────
validate_q15() {
  header "Q15 | NetworkPolicy  [node: cka7968]"

  local np; np=$(kc -n project-snake get netpol np-backend -o jsonpath='{.metadata.name}' 2>/dev/null)
  [[ "$np" == "np-backend" ]] && _pass "NetworkPolicy np-backend exists in project-snake" || _fail "NetworkPolicy np-backend not found in project-snake"

  local sel; sel=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
  [[ "$sel" == "backend" ]] && _pass "NetworkPolicy targets pods with label app=backend" || _fail "NP podSelector expected app=backend, got '$sel'"

  local ptype; ptype=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.policyTypes[0]}' 2>/dev/null)
  [[ "$ptype" == "Egress" ]] && _pass "NetworkPolicy type = Egress only" || _fail "NP policyType expected Egress, got '$ptype'"

  # Check egress rules — expect 2 rules with different ports
  local rule0_port; rule0_port=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.egress[0].ports[0].port}' 2>/dev/null)
  local rule0_dest; rule0_dest=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.egress[0].to[0].podSelector.matchLabels.app}' 2>/dev/null)
  local rule1_port; rule1_port=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.egress[1].ports[0].port}' 2>/dev/null)
  local rule1_dest; rule1_dest=$(kc -n project-snake get netpol np-backend -o jsonpath='{.spec.egress[1].to[0].podSelector.matchLabels.app}' 2>/dev/null)

  if ( [[ "$rule0_port" == "1111" && "$rule0_dest" == "db1" ]] || [[ "$rule1_port" == "1111" && "$rule1_dest" == "db1" ]] ); then
    _pass "Egress rule allows port 1111 to app=db1"
  else
    _fail "Missing egress rule: port 1111 → app=db1 (rule0: $rule0_dest:$rule0_port, rule1: $rule1_dest:$rule1_port)"
  fi

  if ( [[ "$rule0_port" == "2222" && "$rule0_dest" == "db2" ]] || [[ "$rule1_port" == "2222" && "$rule1_dest" == "db2" ]] ); then
    _pass "Egress rule allows port 2222 to app=db2"
  else
    _fail "Missing egress rule: port 2222 → app=db2"
  fi

  # Verify vault is still blocked (connectivity test)
  local be_pod; be_pod=$(kc -n project-snake get pod -l app=backend --no-headers 2>/dev/null | awk '{print $1}' | head -1)
  local vault_ip; vault_ip=$(kc -n project-snake get pod -l app=vault --no-headers -o wide 2>/dev/null | awk '{print $6}' | head -1)
  if [[ -n "$be_pod" && -n "$vault_ip" ]]; then
    local vault_result; vault_result=$(kc -n project-snake exec "$be_pod" -- curl -s --max-time 3 "$vault_ip:3333" 2>/dev/null)
    if [[ -z "$vault_result" ]]; then
      _pass "Connection from backend to vault:3333 is BLOCKED (as required)"
    else
      _fail "Connection from backend to vault:3333 still succeeds — NetworkPolicy may be misconfigured"
    fi
  else
    _skip "Could not find backend/vault pods for live connectivity test"
  fi
}

# ── Q16 — CoreDNS ────────────────────────────────────────────
validate_q16() {
  header "Q16 | Update CoreDNS Configuration  [node: cka5774]"
  local BACKUP="/opt/course/16/coredns_backup.yaml"

  if [[ -f "$BACKUP" ]]; then
    _pass "CoreDNS backup exists at $BACKUP"
    if grep -q "kind: ConfigMap" "$BACKUP" && grep -q "coredns" "$BACKUP"; then
      _pass "Backup file contains CoreDNS ConfigMap"
    else
      _fail "Backup file doesn't look like a CoreDNS ConfigMap"
    fi
  else
    _fail "CoreDNS backup not found at $BACKUP"
    _fail "Backup content check skipped"
  fi

  # Check live ConfigMap has custom-domain
  local corefile; corefile=$(kc -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' 2>/dev/null)
  if echo "$corefile" | grep -q "custom-domain"; then
    _pass "CoreDNS Corefile contains 'custom-domain'"
    if echo "$corefile" | grep "kubernetes" | grep -q "custom-domain" && echo "$corefile" | grep "kubernetes" | grep -q "cluster.local"; then
      _pass "Both 'custom-domain' and 'cluster.local' are on the same kubernetes plugin line"
    else
      _fail "custom-domain and cluster.local should be on the same 'kubernetes' plugin line"
    fi
  else
    _fail "CoreDNS Corefile does NOT contain 'custom-domain'"
    _info "kubernetes line: $(echo "$corefile" | grep kubernetes)"
  fi

  # DNS resolution test
  local bb_pod; bb_pod=$(kc get pod -l run=bb --no-headers 2>/dev/null | awk '{print $1}' | head -1)
  if [[ -n "$bb_pod" ]]; then
    local r1; r1=$(kc exec "$bb_pod" -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null | grep "Address" | grep -v "#53")
    local r2; r2=$(kc exec "$bb_pod" -- nslookup kubernetes.default.svc.custom-domain 2>/dev/null | grep "Address" | grep -v "#53")
    [[ -n "$r1" ]] && _pass "nslookup kubernetes.default.svc.cluster.local resolves ($r1)" || _fail "nslookup kubernetes.default.svc.cluster.local failed"
    [[ -n "$r2" ]] && _pass "nslookup kubernetes.default.svc.custom-domain resolves ($r2)"  || _fail "nslookup kubernetes.default.svc.custom-domain failed — CoreDNS may need a restart"
  else
    _skip "No busybox test pod found (run: k run bb --image=busybox:1 -- sh -c 'sleep 1d')"
    _skip "cluster.local nslookup skipped"
    _skip "custom-domain nslookup skipped"
  fi
}

# ── Q17 — crictl container info ──────────────────────────────
validate_q17() {
  header "Q17 | Find Container of Pod + crictl  [node: cka2556]"
  local TXT="/opt/course/17/pod-container.txt"
  local LOG="/opt/course/17/pod-container.log"

  # pod exists
  local pod_phase; pod_phase=$(kc -n project-tiger get pod tigers-reunite -o jsonpath='{.status.phase}' 2>/dev/null)
  if [[ "$pod_phase" == "Running" ]]; then
    _pass "Pod tigers-reunite is Running in project-tiger"
  else
    _fail "Pod tigers-reunite not Running (phase: $pod_phase)"
  fi

  local pod_img; pod_img=$(kc -n project-tiger get pod tigers-reunite -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
  [[ "$pod_img" == "httpd:2-alpine" ]] && _pass "Pod tigers-reunite uses image httpd:2-alpine" || _fail "Pod image expected httpd:2-alpine, got '$pod_img'"

  # labels
  local lbl_pc; lbl_pc=$(kc -n project-tiger get pod tigers-reunite -o jsonpath='{.metadata.labels.pod}' 2>/dev/null)
  local lbl_cp; lbl_cp=$(kc -n project-tiger get pod tigers-reunite -o jsonpath='{.metadata.labels.container}' 2>/dev/null)
  [[ "$lbl_pc" == "container" ]] && _pass "Pod label pod=container" || _fail "Pod label 'pod' expected 'container', got '$lbl_pc'"
  [[ "$lbl_cp" == "pod" ]]       && _pass "Pod label container=pod" || _fail "Pod label 'container' expected 'pod', got '$lbl_cp'"

  # pod-container.txt
  if [[ -f "$TXT" ]]; then
    _pass "pod-container.txt exists at $TXT"
    local line; line=$(cat "$TXT")

    # Should have a container ID (hex string) and runtimeType
    if echo "$line" | grep -qE '[0-9a-f]{10,}'; then
      _pass "pod-container.txt contains a container ID (hex string)"
    else
      _fail "pod-container.txt should contain a container ID: '$line'"
    fi

    if echo "$line" | grep -q "io.containerd"; then
      _pass "pod-container.txt contains runtimeType (io.containerd.*)"
      _info "$line"
    else
      _fail "pod-container.txt should contain runtimeType like io.containerd.runc.v2, got: '$line'"
    fi
  else
    _fail "pod-container.txt not found at $TXT"
    _fail "container ID check skipped"
    _fail "runtimeType check skipped"
  fi

  # pod-container.log
  if [[ -f "$LOG" ]]; then
    _pass "pod-container.log exists at $LOG"
    if grep -qi "httpd\|apache\|AH0" "$LOG"; then
      _pass "pod-container.log contains httpd/Apache log output"
    else
      _fail "pod-container.log does not look like httpd logs"
      _info "First line: $(head -1 "$LOG")"
    fi
  else
    _fail "pod-container.log not found at $LOG"
    _fail "log content check skipped"
  fi
}

# ── Summary ──────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  RESULTS${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "  ${GREEN}Passed : $PASSED${RESET}"
  echo -e "  ${RED}Failed : $FAILED${RESET}"
  echo -e "  Total  : $TOTAL"
  local score=0
  [[ $TOTAL -gt 0 ]] && score=$(( PASSED * 100 / TOTAL ))
  echo ""
  if [[ $score -ge 80 ]]; then
    echo -e "  ${GREEN}${BOLD}Score : $score% ✓${RESET}"
  elif [[ $score -ge 60 ]]; then
    echo -e "  ${YELLOW}${BOLD}Score : $score%${RESET}"
  else
    echo -e "  ${RED}${BOLD}Score : $score%${RESET}"
  fi
  echo ""
}

# ── Entrypoint ───────────────────────────────────────────────
TARGET="${1:-all}"

case "$TARGET" in
  q1)  validate_q1  ;;
  q2)  validate_q2  ;;
  q3)  validate_q3  ;;
  q4)  validate_q4  ;;
  q5)  validate_q5  ;;
  q6)  validate_q6  ;;
  q7)  validate_q7  ;;
  q8)  validate_q8  ;;
  q9)  validate_q9  ;;
  q10) validate_q10 ;;
  q11) validate_q11 ;;
  q12) validate_q12 ;;
  q13) validate_q13 ;;
  q14) validate_q14 ;;
  q15) validate_q15 ;;
  q16) validate_q16 ;;
  q17) validate_q17 ;;
  all)
    validate_q1; validate_q2; validate_q3; validate_q4; validate_q5
    validate_q6; validate_q7; validate_q8; validate_q9; validate_q10
    validate_q11; validate_q12; validate_q13; validate_q14; validate_q15
    validate_q16; validate_q17
    ;;
  *)
    echo "Usage: $0 [q1|q2|q3|...|q17|all]"
    exit 1
    ;;
esac

print_summary
