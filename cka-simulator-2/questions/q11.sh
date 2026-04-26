#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "11 — Create Secret and Mount into Pod" \
"Solve on: ssh cka2560

Tasks in Namespace 'secret':
  a) Create Namespace 'secret'

  b) Create the existing Secret from /opt/course/11/secret1.yaml
     (update its Namespace to 'secret' first)

  c) Create Secret 'secret2' with:
       user=user1
       pass=1234
     These should be available as env vars APP_USER and APP_PASS

  d) Create Pod 'secret-pod' with image busybox:1
     - Mount secret1 READONLY at /tmp/secret1
     - Expose secret2 values as APP_USER and APP_PASS env vars
     - Keep running with: sleep 1d"

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/11

kubectl create namespace secret --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# secret1.yaml stub for student to use
cat > /opt/course/11/secret1.yaml <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: secret1
  namespace: default
data:
  halt: IyEgL2Jpbi9zaAojIyMgQkVHSU4gSU5JVCBJTkZPCiMgUHJvdmlkZXM6IGhhbHQK
EOF

info "secret1.yaml created at /opt/course/11/secret1.yaml"
info "NOTE: namespace is 'default' — you need to change it to 'secret'"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  Secret as Volume  → files appear inside the container"
echo "  Secret as Env Var → values become environment variables"
echo "  readOnly: true    → container cannot modify mounted secret files"
echo "  secretKeyRef      → pick specific key from a secret for env var"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Create Namespace:${NC}"
cmd "kubectl create namespace secret"

echo ""
echo -e "${BOLD}Step 2 — Fix and apply secret1:${NC}"
cmd "cp /opt/course/11/secret1.yaml /tmp/secret1.yaml"
cmd "vim /tmp/secret1.yaml"
cat <<'CONTENT'
  # Change: namespace: default
  # To:     namespace: secret
CONTENT
cmd "kubectl apply -f /tmp/secret1.yaml"

echo ""
echo -e "${BOLD}Step 3 — Create secret2 from literals:${NC}"
cmd "kubectl -n secret create secret generic secret2 \\"
cmd "  --from-literal=user=user1 \\"
cmd "  --from-literal=pass=1234"

echo ""
echo -e "${BOLD}Step 4 — Create the Pod YAML:${NC}"
cmd "kubectl -n secret run secret-pod --image=busybox:1 --dry-run=client -o yaml -- sh -c 'sleep 1d' > /tmp/secret-pod.yaml"
cmd "vim /tmp/secret-pod.yaml"
cat <<'YAML'

# Full pod YAML:
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
  namespace: secret
spec:
  containers:
  - name: secret-pod
    image: busybox:1
    args: ["sh", "-c", "sleep 1d"]
    env:
    - name: APP_USER
      valueFrom:
        secretKeyRef:
          name: secret2
          key: user
    - name: APP_PASS
      valueFrom:
        secretKeyRef:
          name: secret2
          key: pass
    volumeMounts:
    - name: secret1
      mountPath: /tmp/secret1
      readOnly: true
  volumes:
  - name: secret1
    secret:
      secretName: secret1
YAML

cmd "kubectl apply -f /tmp/secret-pod.yaml"

echo ""
echo -e "${BOLD}Step 5 — Verify:${NC}"
cmd "kubectl -n secret exec secret-pod -- env | grep APP"
cmd "kubectl -n secret exec secret-pod -- find /tmp/secret1"
cmd "kubectl -n secret exec secret-pod -- cat /tmp/secret1/halt"

separator
expected "APP_USER=user1
APP_PASS=1234
/tmp/secret1/halt  ← file exists and is readable"
