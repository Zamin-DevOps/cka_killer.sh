#!/bin/bash
# ─────────────────────────────────────────────
#  CKA Simulator — shared helpers
# ─────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  echo -e "\n${BLUE}${BOLD}════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}${BOLD}  $1${NC}"
  echo -e "${BLUE}${BOLD}════════════════════════════════════════════════${NC}\n"
}

section()  { echo -e "\n${CYAN}${BOLD}── $1 ──${NC}"; }
info()     { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()     { echo -e "${YELLOW}[WARN]${NC} $1"; }
cmd()      { echo -e "  ${YELLOW}➜${NC} $1"; }
tip()      { echo -e "${CYAN}[TIP ]${NC} $1"; }
separator(){ echo -e "\n${BLUE}────────────────────────────────────────────────${NC}\n"; }

expected() {
  echo -e "\n${GREEN}${BOLD}[EXPECTED OUTPUT]${NC}"
  echo -e "$1"
}

question_box() {
  echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║  QUESTION $1${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}\n"
  echo -e "$2\n"
}

wait_for_pod() {
  local ns=$1 label=$2
  info "Waiting for pod ($label) to be Running..."
  kubectl wait pod -n "$ns" -l "$label" \
    --for=condition=Ready --timeout=90s 2>/dev/null \
    || warn "Pod not ready yet — check: k get pod -n $ns"
}
