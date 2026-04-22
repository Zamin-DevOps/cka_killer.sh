# 🧠 CKA Simulator — KillerCoda Edition

A self-contained practice environment for CKA exam questions. Clone this repo into a KillerCoda CKA playground, run any question setup script, and solve it hands-on.

---

## 🚀 Quick Start

```bash
# 1. Clone the repo (on your KillerCoda node)
git clone https://github.com/Zamin-DevOps/cka_killer.sh.git
cd cka-simulator

# 2. Make all scripts executable (one time only)
chmod +x cka.sh questions/*.sh

# 3. List all available questions
./cka.sh

# 4. Set up and start a specific question
./cka.sh 1
```

---

## 📋 Question Index

| #  | Topic                              | Key Concepts                                      | Node      |
|----|------------------------------------|---------------------------------------------------|-----------|
| 1  | Kubeconfig Extraction              | get-contexts, current-context, base64, jsonpath   | cka9412   |
| 2  | MinIO Helm + CRD                   | Helm install, CRD, Operator pattern               | cka7968   |
| 3  | Scale StatefulSet                  | StatefulSet, scale, replicas                      | cka3962   |
| 4  | Find Pods Terminated First         | QoS classes, BestEffort, resource requests        | cka2556   |
| 5  | Kustomize HPA                      | Kustomize, overlays, HPA, base/staging/prod       | cka5774   |
| 6  | PV / PVC / Deployment Volume       | PersistentVolume, PVC, hostPath, volumeMounts     | cka7968   |
| 7  | Node & Pod Resource Usage          | kubectl top, metrics-server, --containers         | cka5774   |
| 8  | Upgrade K8s + Join Node            | kubeadm, kubelet, apt, token, join                | cka3962   |
| 9  | Contact K8s API from Pod           | ServiceAccount, token, curl, RBAC, ca.crt         | cka9412   |
| 10 | RBAC SA + Role + RoleBinding       | Role, RoleBinding, auth can-i, least privilege    | cka3962   |
| 11 | DaemonSet on ALL Nodes             | DaemonSet, tolerations, control-plane scheduling  | cka2556   |
| 12 | One Pod Per Node (Deployment)      | podAntiAffinity, topologySpreadConstraints        | cka2556   |
| 13 | Gateway API HTTPRoute              | HTTPRoute, header matching, rule ordering         | cka7968   |
| 14 | Certificate Expiration Check       | openssl, kubeadm certs, PKI                       | cka9412   |
| 15 | NetworkPolicy Egress               | NetworkPolicy, egress, AND vs OR logic            | cka7968   |
| 16 | CoreDNS Custom Domain              | CoreDNS, ConfigMap, custom-domain, nslookup       | cka5774   |
| 17 | Find Container via crictl          | crictl, containerd, runtimeType, node SSH         | cka2556   |

---

## 🗂️ Repository Structure

```
cka-simulator/
├── cka.sh                  ← Main runner (./cka.sh <number>)
├── README.md
├── lib/
│   └── helpers.sh          ← Shared print/color/setup functions
└── questions/
    ├── q1.sh               ← Kubeconfig
    ├── q2.sh               ← MinIO Helm
    ├── q3.sh               ← StatefulSet scale
    ├── q4.sh               ← QoS / BestEffort
    ├── q5.sh               ← Kustomize HPA
    ├── q6.sh               ← PV/PVC/Deployment
    ├── q7.sh               ← kubectl top scripts
    ├── q8.sh               ← K8s upgrade + join
    ├── q9.sh               ← API from Pod
    ├── q10.sh              ← RBAC
    ├── q11.sh              ← DaemonSet
    ├── q12.sh              ← Pod-per-node Deployment
    ├── q13.sh              ← Gateway API
    ├── q14.sh              ← Cert expiration
    ├── q15.sh              ← NetworkPolicy
    ├── q16.sh              ← CoreDNS
    └── q17.sh              ← crictl
```

---

## 🎯 How Each Question Script Works

When you run `./cka.sh <N>`, the script:

1. **Prints the question** — exactly what you need to accomplish
2. **Sets up the environment** — creates Namespaces, Pods, files, or YAML stubs needed
3. **Shows step-by-step commands** — what to run (but you type them yourself!)
4. **Shows expected output** — so you can verify your answer

> The scripts guide you, but you do the actual work. That's the point! 💪

---

## 💡 Tips

```bash
# Useful aliases to set in KillerCoda (already set by default)
alias k=kubectl
export do='--dry-run=client -o yaml'

# Quick namespace switch
k config set-context --current --namespace=<ns>

# Check your answer quickly
k auth can-i <verb> <resource> --as system:serviceaccount:<ns>:<sa> -n <ns>
```

---

## 🔧 Requirements

- Kubernetes cluster (KillerCoda CKA playground provides this)
- `kubectl` (aliased as `k`)
- `helm` (for Q2)
- `openssl` (for Q14)
- `crictl` or `docker` on worker nodes (for Q17)
- `kubeadm` (for Q8, Q14)

---

## 📚 References

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [KillerCoda CKA Scenarios](https://killercoda.com/killer-shell-cka)
- [killer.sh CKA Simulator](https://killer.sh)

---

*Questions sourced from killer.sh CKA practice exam. For study purposes only.*
