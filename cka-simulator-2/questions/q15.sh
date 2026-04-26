#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "15 — Cluster Event Logging" \
"Solve on: ssh cka6016

Tasks:
  a) Write a kubectl command into /opt/course/15/cluster_events.sh
     that shows the LATEST events in the whole cluster,
     ordered by time (metadata.creationTimestamp)

  b) Delete the kube-proxy Pod.
     Write the events this caused to: /opt/course/15/pod_kill.log

  c) Manually kill the containerd container of the kube-proxy Pod
     (using crictl). Write the events to:
     /opt/course/15/container_kill.log"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/15
info "No pre-setup needed."
info "kube-proxy pod location:"
kubectl -n kube-system get pod -l k8s-app=kube-proxy -o wide 2>/dev/null

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Pod delete   → DaemonSet recreates pod → more events (Killing, SuccessfulCreate, Scheduled)"
echo "  Container kill → Pod still exists, only container restarted → fewer events"
echo "  crictl rm    → kills containerd container (not the pod)"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Part A — Create cluster_events.sh:${NC}"
cmd "cat > /opt/course/15/cluster_events.sh <<'EOF'"
cat <<'CONTENT'
kubectl get events -A --sort-by=.metadata.creationTimestamp
EOF
CONTENT
cmd "chmod +x /opt/course/15/cluster_events.sh"
cmd "# Test it:"
cmd "sh /opt/course/15/cluster_events.sh | tail -20"

echo ""
echo -e "${BOLD}Part B — Delete kube-proxy Pod and capture events:${NC}"
cmd "kubectl -n kube-system get pod -l k8s-app=kube-proxy"
cmd "kubectl -n kube-system delete pod <kube-proxy-pod-name>"
cmd "# Wait a few seconds, then:"
cmd "sh /opt/course/15/cluster_events.sh | tail -20 > /opt/course/15/pod_kill.log"
cmd "cat /opt/course/15/pod_kill.log"

echo ""
echo -e "${BOLD}Part C — Kill the container with crictl:${NC}"
cmd "sudo -i"
cmd "# Find the kube-proxy container ID:"
cmd "crictl ps | grep kube-proxy"
cmd "# Kill it (note the container ID):"
cmd "crictl rm --force <container-id>"
cmd "# Verify it restarted:"
cmd "crictl ps | grep kube-proxy"
cmd "# Capture events:"
cmd "sh /opt/course/15/cluster_events.sh | tail -20 > /opt/course/15/container_kill.log"
cmd "cat /opt/course/15/container_kill.log"

separator
section "Compare the two log files"
echo "  pod_kill.log      → MORE events (DaemonSet involved: Killing, Create, Scheduled)"
echo "  container_kill.log → FEWER events (only container restart: Created, Started)"
cmd "diff /opt/course/15/pod_kill.log /opt/course/15/container_kill.log"

separator
expected "cluster_events.sh  → shows all events sorted by time
pod_kill.log       → events: Killing, SuccessfulCreate, Scheduled, Pulled, Created, Started
container_kill.log → events: Created, Started (fewer — pod still existed)"
