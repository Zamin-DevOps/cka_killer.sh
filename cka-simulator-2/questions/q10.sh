#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "10 — PV / PVC Dynamic Provisioning" \
"Solve on: ssh cka6016

There is a backup Job at /opt/course/10/backup.yaml

Tasks:
  a) Create a StorageClass named 'local-backup':
     - provisioner: rancher.io/local-path
     - volumeBindingMode: WaitForFirstConsumer
     - reclaimPolicy: Retain  (keep PV even if PVC deleted)

  b) Adjust the Job to use a PVC instead of emptyDir:
     - PVC name: backup-pvc  in namespace: project-bern
     - storage request: 50Mi
     - storageClassName: local-backup

  c) Deploy changes. Verify Job completed and PVC is Bound."

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/10

kubectl create namespace project-bern --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# Original backup.yaml with emptyDir (student must update it)
cat > /opt/course/10/backup.yaml <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: backup
  namespace: project-bern
spec:
  backoffLimit: 0
  template:
    spec:
      volumes:
        - name: backup
          emptyDir: {}
      containers:
        - name: bash
          image: bash:5
          command:
            - bash
            - -c
            - |
              set -x
              touch /backup/backup-$(date +%Y-%m-%d-%H-%M-%S).tar.gz
              sleep 15
          volumeMounts:
            - name: backup
              mountPath: /backup
      restartPolicy: Never
EOF

info "Original backup.yaml with emptyDir created at /opt/course/10/backup.yaml"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  emptyDir     → temp storage, deleted when Pod dies"
echo "  PVC + Retain → storage survives Pod/PVC deletion"
echo "  WaitForFirstConsumer → PV created only when Pod is scheduled"
echo "  Dynamic provisioning → StorageClass creates PV automatically"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Create StorageClass:${NC}"
cmd "kubectl apply -f - <<'EOF'"
cat <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-backup
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
YAML
cmd "kubectl get sc local-backup"

echo ""
echo -e "${BOLD}Step 2 — Update backup.yaml (add PVC + change volume type):${NC}"
cmd "cp /opt/course/10/backup.yaml /opt/course/10/backup.yaml.orig"
cmd "vim /opt/course/10/backup.yaml"
cat <<'YAML'

# Final backup.yaml should look like this:
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: project-bern
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Mi
  storageClassName: local-backup
---
apiVersion: batch/v1
kind: Job
metadata:
  name: backup
  namespace: project-bern
spec:
  backoffLimit: 0
  template:
    spec:
      volumes:
        - name: backup
          persistentVolumeClaim:   # ← CHANGED from emptyDir
            claimName: backup-pvc  # ← NEW
      containers:
        - name: bash
          image: bash:5
          command:
            - bash
            - -c
            - |
              set -x
              touch /backup/backup-$(date +%Y-%m-%d-%H-%M-%S).tar.gz
              sleep 15
          volumeMounts:
            - name: backup
              mountPath: /backup
      restartPolicy: Never
YAML

echo ""
echo -e "${BOLD}Step 3 — Delete old job if exists, then apply:${NC}"
cmd "kubectl -n project-bern delete job backup --ignore-not-found"
cmd "kubectl apply -f /opt/course/10/backup.yaml"

echo ""
echo -e "${BOLD}Step 4 — Verify:${NC}"
cmd "kubectl -n project-bern get job,pod,pvc,pv"
cmd "# Job STATUS: Complete"
cmd "# PVC STATUS: Bound"
cmd "# PV  RECLAIM POLICY: Retain"

separator
expected "job.batch/backup      Complete   1/1
pvc/backup-pvc        Bound
pv/pvc-xxxx           Retain   Bound"
