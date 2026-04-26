#!/bin/bash
# ─────────────────────────────────────────────
#  CKA Simulator — main runner
#  Usage: ./cka.sh [question_number]
# ─────────────────────────────────────────────
source "$(dirname "$0")/lib/helpers.sh"

QUESTIONS=(
  "1  | DNS / FQDN / Headless Service        | FQDN, headless, pod DNS"
  "2  | Static Pod + NodePort Service        | static pod, expose, NodePort"
  "3  | Kubelet Cert Info                    | openssl, client/server cert"
  "4  | Pod Ready if Service Reachable       | readinessProbe, init container"
  "5  | Kubectl Sorting                      | --sort-by, jsonpath, top"
  "6  | Fix Kubelet                          | systemd, binary path, journalctl"
  "7  | Etcd Operations                      | etcdctl, snapshot, restore"
  "8  | Get Controlplane Information         | static-pod, process, CNI, CIDR"
  "9  | Kill Scheduler / Manual Scheduling   | nodeName, scheduler, static pod"
  "10 | PV PVC Dynamic Provisioning         | StorageClass, Retain, Job"
  "11 | Create Secret + Mount into Pod       | secret, env, volumeMount"
  "12 | Schedule Pod on Controlplane         | toleration, nodeSelector"
  "13 | Multi Containers + Shared Volume     | emptyDir, fieldRef, sidecar"
  "14 | Find Cluster Information             | CNI, CIDR, static-pod suffix"
  "15 | Cluster Event Logging               | events, crictl, pod kill"
  "16 | Namespaces and Api Resources        | api-resources, roles, count"
  "17 | Operator CRDs RBAC Kustomize        | CRD, kustomize, RBAC, student"
)

list_questions() {
  banner "CKA Simulator — KillerCoda Edition"
  echo -e "${BOLD}Available Questions:${NC}\n"
  printf "  ${CYAN}%-4s %-42s %s${NC}\n" "No." "Topic" "Key Concepts"
  echo "  ──────────────────────────────────────────────────────────────────"
  for q in "${QUESTIONS[@]}"; do
    IFS='|' read -r num topic concepts <<< "$q"
    printf "  ${GREEN}Q%-3s${NC} ${BOLD}%-42s${NC} ${YELLOW}%s${NC}\n" \
      "$(echo $num | xargs)" "$(echo $topic | xargs)" "$(echo $concepts | xargs)"
  done
  echo ""
  echo -e "Usage: ${BOLD}./cka.sh <number>${NC}    e.g.  ./cka.sh 6"
  echo ""
}

run_question() {
  local n=$1
  local script="$(dirname "$0")/questions/q${n}.sh"
  if [[ ! -f "$script" ]]; then
    echo -e "${RED}[ERROR]${NC} Question $n script not found at $script"
    exit 1
  fi
  chmod +x "$script"
  bash "$script"
}

if [[ -z "$1" ]]; then
  list_questions
else
  run_question "$1"
fi
