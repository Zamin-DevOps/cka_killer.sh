#!/bin/bash
# DESC: Node & Pod Resource Usage - kubectl top scripts
# NODE: cka5774

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

OUT_DIR="/opt/course/7"

print_header "Q7 | Node and Pod Resource Usage"

print_section "Task"
print_task "Create /opt/course/7/node.sh - shows resource usage of nodes"
print_task "Create /opt/course/7/pod.sh  - shows resource usage of Pods and containers"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"
print_success "Output directory ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Explore kubectl top:${RESET}"
print_cmd "k top -h"
print_cmd "k top node"
print_cmd "k top pod --containers=true"
echo ""

echo -e "${BOLD}Step 2 - Create node.sh:${RESET}"
print_cmd "vim $OUT_DIR/node.sh"
echo ""
echo -e "  ${GREEN}Content:${RESET}"
echo "  #!/bin/bash"
echo "  kubectl top node"
echo ""

echo -e "${BOLD}Step 3 - Create pod.sh:${RESET}"
print_cmd "vim $OUT_DIR/pod.sh"
echo ""
echo -e "  ${GREEN}Content:${RESET}"
echo "  #!/bin/bash"
echo "  kubectl top pod --containers=true"
echo ""

echo -e "${BOLD}Step 4 - Make executable and test:${RESET}"
print_cmd "chmod +x $OUT_DIR/node.sh $OUT_DIR/pod.sh"
print_cmd "bash $OUT_DIR/node.sh"
print_cmd "bash $OUT_DIR/pod.sh"
echo ""

print_hint "Use full command 'kubectl' not alias 'k' in scripts for portability"
print_note "--containers=true shows each container's usage within a Pod"
divider
