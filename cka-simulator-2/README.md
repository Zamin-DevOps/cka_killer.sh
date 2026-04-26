# CKA Simulator — KillerCoda Edition

A self-contained practice environment for CKA exam questions. Clone this repo into a KillerCoda CKA playground, run any question setup script, and solve it hands-on.

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

## 📋 Question Index

| # | Topic | Key Concepts | Node |
|---|-------|-------------|------|
| 1 | DNS / FQDN / Headless Service | FQDN, headless svc, pod DNS | cka6016 |
| 2 | Static Pod + NodePort Service | static pod, manifests dir, expose | cka2560 |
| 3 | Kubelet Client/Server Cert Info | openssl, client cert, server cert | cka5248 |
| 4 | Pod Ready if Service Reachable | readinessProbe, tcpSocket | cka5248 |
| 5 | Kubectl Sorting | --sort-by, jsonpath, creationTimestamp | cka5248 |
| 6 | Fix Kubelet | systemd, binary path, 203/EXEC | cka1024 |
| 7 | Etcd Operations | etcdctl, snapshot, etcdutl restore | cka2560 |
| 8 | Get Controlplane Information | static-pod, process, CNI, CIDR | cka8448 |
| 9 | Kill Scheduler / Manual Scheduling | nodeName, kube-scheduler, manifests | cka5248 |
| 10 | PV / PVC Dynamic Provisioning | StorageClass, Retain, Job, emptyDir | cka6016 |
| 11 | Create Secret + Mount into Pod | secret, env, volumeMount, readOnly | cka2560 |
| 12 | Schedule Pod on Controlplane | toleration, nodeSelector, taint | cka5248 |
| 13 | Multi Containers + Shared Volume | emptyDir, fieldRef, sidecar, c1/c2/c3 | cka3200 |
| 14 | Find Cluster Information | CNI, CIDR, static-pod suffix | cka8448 |
| 15 | Cluster Event Logging | events, crictl rm, pod kill, container kill | cka6016 |
| 16 | Namespaces and Api Resources | api-resources, roles, count | cka3200 |
| 17 | Operator, CRDs, RBAC, Kustomize | CRD, kustomize base/prod, RBAC | cka6016 |

## 🗂️ Repository Structure

```
cka-simulator/
├── cka.sh                  ← Main runner (./cka.sh <number>)
├── README.md
├── lib/
│   └── helpers.sh          ← Shared print/color/setup functions
└── questions/
    ├── q1.sh               ← DNS / FQDN / Headless Service
    ├── q2.sh               ← Static Pod + NodePort Service
    ├── q3.sh               ← Kubelet Cert Info
    ├── q4.sh               ← Pod Ready if Service Reachable
    ├── q5.sh               ← Kubectl Sorting
    ├── q6.sh               ← Fix Kubelet
    ├── q7.sh               ← Etcd Operations
    ├── q8.sh               ← Get Controlplane Information
    ├── q9.sh               ← Kill Scheduler / Manual Scheduling
    ├── q10.sh              ← PV / PVC Dynamic Provisioning
    ├── q11.sh              ← Create Secret + Mount into Pod
    ├── q12.sh              ← Schedule Pod on Controlplane
    ├── q13.sh              ← Multi Containers + Shared Volume
    ├── q14.sh              ← Find Cluster Information
    ├── q15.sh              ← Cluster Event Logging
    ├── q16.sh              ← Namespaces and Api Resources
    └── q17.sh              ← Operator, CRDs, RBAC, Kustomize
```

## 🎯 How Each Question Script Works

When you run `./cka.sh <N>`, the script:

1. **Prints the question** — exactly what you need to accomplish
2. **Sets up the environment** — creates Namespaces, Pods, broken configs, YAML stubs
3. **Shows step-by-step guide** — what commands to run (but YOU type them!)
4. **Shows expected output** — so you can verify your answer

The scripts guide you, but you do the actual work. That's the point! 💪

## 💡 Tips

```bash
# Useful aliases (set these in KillerCoda)
alias k=kubectl
export do='--dry-run=client -o yaml'
export now='--force --grace-period=0'

# Quick namespace switch
k config set-context --current --namespace=<ns>

# Check RBAC permissions
k auth can-i <verb> <resource> --as system:serviceaccount:<ns>:<sa> -n <ns>

# Find where kubelet binary is
whereis kubelet

# Check static pod manifests
ls /etc/kubernetes/manifests/

# Check CNI config
find /etc/cni/net.d/
```

## 🔧 Requirements

- Kubernetes cluster (KillerCoda CKA playground provides this)
- `kubectl` (aliased as `k`)
- `openssl` (for Q3, Q14)
- `crictl` on nodes (for Q15)
- `kubeadm` (for Q7, Q8)
- `etcdctl` / `etcdutl` (for Q7)

## 📚 DNS FQDN Quick Reference (Q1)

| Type | Format | Example |
|------|--------|---------|
| Service | `SVC.NS.svc.cluster.local` | `kubernetes.default.svc.cluster.local` |
| Headless Svc | `SVC.NS.svc.cluster.local` | `department.lima-workload.svc.cluster.local` |
| Named Pod | `HOSTNAME.SVC.NS.svc.cluster.local` | `section100.section.lima-workload.svc.cluster.local` |
| Pod by IP | `1-2-3-4.NS.pod.cluster.local` | `1-2-3-4.kube-system.pod.cluster.local` |
