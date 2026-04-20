#!/bin/bash
# ============================================================
#  CKA Simulator - Main Runner
#  Usage: ./cka.sh <question_number>
#  Example: ./cka.sh 1
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUESTIONS_DIR="$SCRIPT_DIR/questions"
LIB_DIR="$SCRIPT_DIR/lib"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

banner() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║           CKA Simulator - KillerCoda Edition             ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

list_questions() {
  echo -e "${BOLD}Available Questions:${RESET}"
  echo ""
  for f in "$QUESTIONS_DIR"/q*.sh; do
    [ -f "$f" ] || continue
    num=$(basename "$f" | grep -o '[0-9]*')
    desc=$(grep '^# DESC:' "$f" | sed 's/# DESC: //')
    node=$(grep '^# NODE:' "$f" | sed 's/# NODE: //')
    printf "  ${GREEN}%-4s${RESET} %-45s ${YELLOW}[%s]${RESET}\n" "Q$num" "$desc" "$node"
  done
  echo ""
  echo -e "Usage: ${CYAN}./cka.sh <number>${RESET}   e.g. ./cka.sh 3"
  echo ""
}

run_question() {
  local num="$1"
  local script="$QUESTIONS_DIR/q${num}.sh"

  if [ ! -f "$script" ]; then
    echo -e "${RED}❌ Question $num not found.${RESET}"
    echo ""
    list_questions
    exit 1
  fi

  source "$LIB_DIR/helpers.sh"
  bash "$script"
}

banner

if [ $# -eq 0 ]; then
  list_questions
  exit 0
fi

case "$1" in
  list|ls|-l) list_questions ;;
  [0-9]*) run_question "$1" ;;
  *)
    echo -e "${RED}Unknown argument: $1${RESET}"
    list_questions
    exit 1
    ;;
esac
