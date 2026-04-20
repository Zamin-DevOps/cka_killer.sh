#!/bin/bash
# ============================================================
#  CKA Simulator - Helper Library
#  Sourced by each question script
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Print helpers ────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════${RESET}"
  echo -e "${CYAN}${BOLD}  $1${RESET}"
  echo -e "${CYAN}${BOLD}══════════════════════════════════════════════════════════${RESET}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${BLUE}${BOLD}▶ $1${RESET}"
  echo -e "${BLUE}──────────────────────────────────────${RESET}"
}

print_task() {
  echo -e "  ${YELLOW}📋 $1${RESET}"
}

print_hint() {
  echo -e "  ${GREEN}💡 Hint: $1${RESET}"
}

print_note() {
  echo -e "  ${CYAN}ℹ️  $1${RESET}"
}

print_success() {
  echo -e "  ${GREEN}✅ $1${RESET}"
}

print_warn() {
  echo -e "  ${YELLOW}⚠️  $1${RESET}"
}

print_cmd() {
  echo -e "  ${BOLD}\$ $1${RESET}"
}

divider() {
  echo -e "${CYAN}──────────────────────────────────────────────────────────${RESET}"
}

# ── Setup helpers ─────────────────────────────────────────────
setup_output_dir() {
  local dir="$1"
  mkdir -p "$dir"
  print_success "Output directory ready: $dir"
}

check_kubectl() {
  if ! command -v kubectl &>/dev/null && ! command -v k &>/dev/null; then
    echo -e "${RED}❌ kubectl not found. Are you in the right environment?${RESET}"
    exit 1
  fi
}

wait_for_pod_ready() {
  local ns="$1"
  local name="$2"
  local timeout="${3:-60}"
  echo -ne "  ⏳ Waiting for pod $name to be ready..."
  kubectl wait pod "$name" -n "$ns" --for=condition=Ready --timeout="${timeout}s" &>/dev/null && \
    echo -e " ${GREEN}Ready!${RESET}" || echo -e " ${YELLOW}Timeout (may still be starting)${RESET}"
}

alias_k() {
  # Ensure 'k' works as kubectl alias in scripts
  if ! command -v k &>/dev/null; then
    alias k='kubectl'
  fi
}
