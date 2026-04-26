#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "13 — Multi Containers and Pod Shared Volume" \
"Solve on: ssh cka3200

Create Pod 'multi-container-playground' in Namespace 'default':

  Volume: emptyDir (not persisted, not shared with other Pods)

  Container c1: image nginx:1-alpine
    - Env var MY_NODE_NAME = name of node where Pod is running

  Container c2: image busybox:1
    - Write 'date' output every second to /vol/date.log
    - Command: while true; do date >> /vol/date.log; sleep 1; done

  Container c3: image busybox:1
    - Continuously print content of /vol/date.log to stdout
    - Command: tail -f /vol/date.log

Verify: check logs of c3 to confirm setup works"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
info "No pre-setup needed."

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  emptyDir          → shared between ALL containers in same Pod"
echo "  c2 writes to file → c3 reads from same file (shared volume)"
echo "  fieldRef          → inject Pod/Node info as env var (Downward API)"
echo "  spec.nodeName     → the node this pod runs on"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Create the Pod YAML:${NC}"
cmd "vim /tmp/multi.yaml"
cat <<'YAML'

# Complete multi-container-playground.yaml:
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-playground
  namespace: default
spec:
  containers:

  - image: nginx:1-alpine
    name: c1
    env:
    - name: MY_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName    # Downward API — injects node name
    volumeMounts:
    - name: vol
      mountPath: /vol

  - image: busybox:1
    name: c2
    command: ["sh", "-c", "while true; do date >> /vol/date.log; sleep 1; done"]
    volumeMounts:
    - name: vol
      mountPath: /vol               # same mountPath = same shared directory

  - image: busybox:1
    name: c3
    command: ["sh", "-c", "tail -f /vol/date.log"]
    volumeMounts:
    - name: vol
      mountPath: /vol               # same mountPath = reads what c2 writes

  volumes:
  - name: vol
    emptyDir: {}                    # {} = default emptyDir (in-memory or disk)

  dnsPolicy: ClusterFirst
  restartPolicy: Always
YAML

echo ""
echo -e "${BOLD}Step 2 — Apply:${NC}"
cmd "kubectl apply -f /tmp/multi.yaml"
cmd "kubectl get pod multi-container-playground"
cmd "# All 3 containers should show: 3/3 Running"

echo ""
echo -e "${BOLD}Step 3 — Verify c1 has node name env var:${NC}"
cmd "kubectl exec multi-container-playground -c c1 -- env | grep MY_NODE_NAME"

echo ""
echo -e "${BOLD}Step 4 — Verify c3 logs show date output from c2:${NC}"
cmd "kubectl logs multi-container-playground -c c3"
cmd "# Should show lines like:"
cmd "# Tue Nov  5 13:41:33 UTC 2024"
cmd "# Tue Nov  5 13:41:34 UTC 2024"

separator
expected "Pod:            3/3 Running
MY_NODE_NAME:   <node-name>
c3 logs:        date lines appearing every second"
