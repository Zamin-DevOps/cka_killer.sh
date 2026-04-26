#!/bin/bash
source "$(dirname "$0")/../lib/helpers.sh"

question_box "17 — Operator, CRDs, RBAC, Kustomize" \
"Solve on: ssh cka6016

Kustomize config is at /opt/course/17/operator
It was deployed like this:
  kubectl kustomize /opt/course/17/operator/prod | kubectl apply -f -

Tasks:
  a) Check operator logs to find which CRDs it cannot list.
     Fix the Role 'operator-role' permissions in Kustomize BASE config.

  b) Add a new Student resource 'student4' with any name and description
     in the Kustomize BASE config.

  c) Re-deploy using kustomize prod and verify no errors in logs."

# ── SETUP ──────────────────────────────────────────────────────────────
section "Setting up environment..."
mkdir -p /opt/course/17/operator/base
mkdir -p /opt/course/17/operator/prod

kubectl create namespace operator-prod --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null

# CRD: students
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: students.education.killer.sh
spec:
  group: education.killer.sh
  names:
    kind: Student
    listKind: StudentList
    plural: students
    singular: student
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              name:
                type: string
              description:
                type: string
EOF

# CRD: classes
kubectl apply -f - 2>/dev/null <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: classes.education.killer.sh
spec:
  group: education.killer.sh
  names:
    kind: Class
    listKind: ClassList
    plural: classes
    singular: class
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              name:
                type: string
EOF

# Base YAML files
cat > /opt/course/17/operator/base/sa.yaml <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: operator
  namespace: NAMESPACE_REPLACE
EOF

# Role with MISSING permissions (student must fix)
cat > /opt/course/17/operator/base/rbac.yaml <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator-role
  namespace: default
rules: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: operator-rolebinding
  namespace: default
subjects:
  - kind: ServiceAccount
    name: operator
    namespace: default
roleRef:
  kind: Role
  name: operator-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Students CR
cat > /opt/course/17/operator/base/students.yaml <<'EOF'
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student1
spec:
  name: Alice Johnson
  description: A student learning Kubernetes basics
---
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student2
spec:
  name: Bob Smith
  description: A student practicing CKA scenarios
---
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student3
spec:
  name: Carol Williams
  description: A student excelling in container orchestration
EOF

# Base kustomization
cat > /opt/course/17/operator/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - sa.yaml
  - rbac.yaml
  - students.yaml
EOF

# Deployment that tries to list students and classes
cat > /opt/course/17/operator/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: operator
  namespace: NAMESPACE_REPLACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: operator
  template:
    metadata:
      labels:
        app: operator
    spec:
      serviceAccountName: operator
      containers:
      - name: operator
        image: bitnami/kubectl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            kubectl get students
            kubectl get classes
            sleep 60
          done
EOF

# Update base kustomization to include deployment
cat > /opt/course/17/operator/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - sa.yaml
  - rbac.yaml
  - students.yaml
  - deployment.yaml
EOF

# Prod overlay
cat > /opt/course/17/operator/prod/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: operator-prod
resources:
  - ../base
namePrefix: ""
patches:
  - patch: |-
      - op: replace
        path: /metadata/namespace
        value: operator-prod
    target:
      kind: Deployment
      name: operator
EOF

# Deploy initial (broken) version
kubectl kustomize /opt/course/17/operator/prod | kubectl apply -f - 2>/dev/null

info "Kustomize operator deployed to namespace 'operator-prod'"
warn "The operator Role has NO permissions — it will show Forbidden errors in logs"
info "Run: kubectl -n operator-prod logs <operator-pod-name>"

# ── GUIDE ──────────────────────────────────────────────────────────────
separator
section "Key Concept"
echo "  CRD resources need their own apiGroup in Role rules"
echo "  Standard resources use apiGroup: ''"
echo "  CRDs use their group: e.g. education.killer.sh"
echo "  Kustomize: edit BASE files — prod overlay inherits automatically"

separator
section "Step-by-step Guide (YOU type these)"

echo -e "${BOLD}Step 1 — Check operator logs for errors:${NC}"
cmd "kubectl -n operator-prod get pod"
cmd "kubectl -n operator-prod logs <operator-pod-name>"
cmd "# You'll see: Forbidden: cannot list resource 'students'"
cmd "#              Forbidden: cannot list resource 'classes'"

echo ""
echo -e "${BOLD}Step 2 — Fix Role in base/rbac.yaml:${NC}"
cmd "vim /opt/course/17/operator/base/rbac.yaml"
cat <<'YAML'

# Update the Role rules section:
rules:
- apiGroups:
  - education.killer.sh      # ← CRD group (NOT "" like for pods/services)
  resources:
  - students                 # ← operator tried to list this
  - classes                  # ← operator tried to list this
  verbs:
  - list                     # ← only list is needed
YAML

echo ""
echo -e "${BOLD}Step 3 — Add student4 to base/students.yaml:${NC}"
cmd "vim /opt/course/17/operator/base/students.yaml"
cat <<'YAML'

# Append at the end of the file:
---
apiVersion: education.killer.sh/v1
kind: Student
metadata:
  name: student4
spec:
  name: Some Name
  description: Some Description
YAML

echo ""
echo -e "${BOLD}Step 4 — Re-deploy with kustomize:${NC}"
cmd "kubectl kustomize /opt/course/17/operator/prod | kubectl apply -f -"
cmd "# Output should show: role configured, student4 created"

echo ""
echo -e "${BOLD}Step 5 — Verify logs are clean:${NC}"
cmd "kubectl -n operator-prod rollout restart deploy operator"
cmd "kubectl -n operator-prod logs -f <new-pod-name>"
cmd "# Should show: students listed, classes listed — NO Forbidden errors"
cmd "kubectl -n operator-prod get student"

separator
expected "Operator logs:
  NAME       AGE
  student1   Xm
  student2   Xm
  student3   Xm
  student4   Xs   ← new one

  NAME       AGE
  advanced   Xm   ← classes also listed OK"
