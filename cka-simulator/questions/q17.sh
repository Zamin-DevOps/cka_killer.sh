#!/bin/bash
# DESC: Find Pod container on node using crictl, write ID + logs
# NODE: cka2556

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

NS="project-tiger"
OUT_DIR="/opt/course/17"

print_header "Q17 | Find Container of Pod and Check Info"

print_section "Task"
echo -e "  ${BOLD}1.${RESET} Create Pod ${CYAN}tigers-reunite${RESET} in ns ${CYAN}$NS${RESET}"
echo -e "       image: ${CYAN}httpd:2-alpine${RESET}"
echo -e "       labels: ${CYAN}pod=container, container=pod${RESET}"
echo -e "  ${BOLD}2.${RESET} Find which node the Pod is scheduled on"
echo -e "  ${BOLD}3.${RESET} SSH into that node and use ${CYAN}crictl${RESET} to find the container"
echo -e "  ${BOLD}4.${RESET} Write container ID + runtimeType to ${CYAN}$OUT_DIR/pod-container.txt${RESET}"
echo -e "  ${BOLD}5.${RESET} Write container logs to ${CYAN}$OUT_DIR/pod-container.log${RESET}"
echo ""

print_section "Environment Setup"
setup_output_dir "$OUT_DIR"
kubectl get ns "$NS" &>/dev/null || kubectl create ns "$NS"
print_success "Namespace $NS ready, output dir ready"
echo ""

print_section "Your Tasks - Commands to Run"

echo ""
echo -e "${BOLD}Step 1 - Create the Pod:${RESET}"
print_cmd "k -n $NS run tigers-reunite --image=httpd:2-alpine --labels 'pod=container,container=pod'"
echo ""

echo -e "${BOLD}Step 2 - Find which node it's on:${RESET}"
print_cmd "k -n $NS get pod tigers-reunite -o wide"
echo ""
echo -e "  Look at the ${CYAN}NODE${RESET} column"
echo ""

echo -e "${BOLD}Step 3 - SSH into that node:${RESET}"
print_cmd "ssh <node-name>       # e.g. ssh cka2556-node1"
print_cmd "sudo -i"
echo ""

echo -e "${BOLD}Step 4 - Find the container with crictl:${RESET}"
print_cmd "crictl ps | grep tigers-reunite"
echo ""
echo -e "  Output:"
echo "  CONTAINER ID   IMAGE    CREATED   STATE   NAME            ..."
echo "  ba62e5d465ff0  ...      2m ago    Running tigers-reunite  ..."
echo ""

echo -e "${BOLD}Step 5 - Get runtimeType from container inspect:${RESET}"
print_cmd "crictl inspect <container-id> | grep runtimeType"
echo ""
echo -e "  Output:"
echo '  "runtimeType": "io.containerd.runc.v2"'
echo ""

echo -e "${BOLD}Step 6 - Write container ID + runtimeType to file:${RESET}"
echo -e "  ${YELLOW}Exit the node and write from controlplane:${RESET}"
print_cmd "exit"
echo ""
echo -e "  Create the file on controlplane:"
print_cmd "echo '<container-id> io.containerd.runc.v2' > $OUT_DIR/pod-container.txt"
echo ""
echo -e "  Example:"
echo "  echo 'ba62e5d465ff0 io.containerd.runc.v2' > $OUT_DIR/pod-container.txt"
echo ""

echo -e "${BOLD}Step 7 - Get container logs:${RESET}"
print_cmd "ssh <node-name>"
print_cmd "sudo crictl logs <container-id>"
echo ""
echo -e "  Copy output manually, then exit and save:"
print_cmd "exit"
print_cmd "cat > $OUT_DIR/pod-container.log << 'EOF'"
echo "  <paste crictl logs output here>"
print_cmd "EOF"
echo ""
echo -e "  ${CYAN}Or automate with:${RESET}"
print_cmd "ssh <node-name> 'sudo crictl logs \$(sudo crictl ps | grep tigers-reunite | awk \"{print \\\$1}\")' > $OUT_DIR/pod-container.log"
echo ""

print_section "Expected Output Files"
echo ""
echo -e "  ${CYAN}$OUT_DIR/pod-container.txt${RESET}"
echo "  ba62e5d465ff0 io.containerd.runc.v2"
echo ""
echo -e "  ${CYAN}$OUT_DIR/pod-container.log${RESET}"
echo "  AH00558: httpd: Could not reliably determine..."
echo "  [mpm_event:notice] ... Apache configured -- resuming normal operations"
echo "  [core:notice] ... Command line: 'httpd -D FOREGROUND'"
echo ""

print_section "Crictl Cheat Sheet"
echo -e "  ${BOLD}crictl ps${RESET}               List running containers"
echo -e "  ${BOLD}crictl ps -a${RESET}             List all containers (including stopped)"
echo -e "  ${BOLD}crictl inspect <id>${RESET}      Inspect container"
echo -e "  ${BOLD}crictl logs <id>${RESET}         Get container logs"
echo -e "  ${BOLD}crictl pods${RESET}              List pods (sandbox level)"
echo -e "  ${BOLD}crictl images${RESET}            List images"
echo ""

print_hint "crictl must be run as root (use sudo -i or sudo crictl)"
print_hint "Container ID in crictl is different from Pod name — use grep to filter"
print_note "In some exam environments docker may be used instead of crictl — same arguments work"
divider
