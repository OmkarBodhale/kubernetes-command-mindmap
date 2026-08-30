# 🏆 Top 50 kubectl Commands

**Ranked by how often DevOps and SRE engineers actually run them — not alphabetically, not by topic completeness.**

> 🎯 **You have 5 minutes before an interview?** Read the first 20. They cover most of what anyone will ask you to demonstrate.

---

## 🥇 The Top 10 — you will type these every day

| # | Command | Why |
| --- | --- | --- |
| 1 | `kubectl get pods` | The single most-run Kubernetes command |
| 2 | `kubectl describe pod <pod-name>` | Detail + events. Read it bottom-up. |
| 3 | `kubectl logs <pod-name>` | What the application said |
| 4 | `kubectl logs <pod-name> --previous` | What it said **before it crashed** ⭐ |
| 5 | `kubectl get pods -o wide` | Adds Pod IP and node |
| 6 | `kubectl exec -it <pod-name> -- /bin/sh` | Shell inside the container |
| 7 | `kubectl apply -f <file>.yaml` | Deploy or update |
| 8 | `kubectl get svc` | List Services |
| 9 | `kubectl config current-context` | **Which cluster am I on?** ⭐ |
| 10 | `kubectl get all -n <namespace>` | Quick namespace overview ⚠️ *not literally everything* |

> ⭐ #4 and #9 are the two most under-used commands in Kubernetes. `--previous` solves most crash investigations; `current-context` prevents most incidents.

---

## ☸️ Cluster (11–15)

| # | Command | Why |
| --- | --- | --- |
| 11 | `kubectl get nodes` | Is the platform healthy? |
| 12 | `kubectl get nodes -o wide` | IPs, OS, kubelet version |
| 13 | `kubectl cluster-info` | API server endpoint |
| 14 | `kubectl config get-contexts` | What clusters can I reach? |
| 15 | `kubectl config use-context <context-name>` | Switch cluster |

---

## 📦 Pods (16–21)

| # | Command | Why |
| --- | --- | --- |
| 16 | `kubectl get pods -A` | Every namespace |
| 17 | `kubectl get pods -w` | Watch changes live |
| 18 | `kubectl delete pod <pod-name>` | Force a replacement |
| 19 | `kubectl logs -f <pod-name>` | Follow live logs |
| 20 | `kubectl logs <pod-name> -c <container-name>` | Multi-container Pod |
| 21 | `kubectl port-forward pod/<pod-name> 8080:80` | Reach it from your laptop |

---

## 🚀 Deployments (22–28)

| # | Command | Why |
| --- | --- | --- |
| 22 | `kubectl get deployments` | Rollout state at a glance |
| 23 | `kubectl rollout status deployment/<name>` | Did the deploy finish? |
| 24 | `kubectl rollout restart deployment/<name>` | **The correct way to restart an app** ⭐ |
| 25 | `kubectl rollout undo deployment/<name>` | Roll back |
| 26 | `kubectl rollout history deployment/<name>` | What versions exist |
| 27 | `kubectl scale deployment/<name> --replicas=<n>` | Change replica count |
| 28 | `kubectl set image deployment/<name> <container>=<image>` | Deploy a new image |

---

## 🌐 Networking (29–33)

| # | Command | Why |
| --- | --- | --- |
| 29 | `kubectl get endpoints <service-name>` | **Is the Service wired to Pods?** ⭐⭐ |
| 30 | `kubectl describe svc <service-name>` | Ports, selector, endpoints |
| 31 | `kubectl port-forward svc/<service-name> 8080:80` | Test a Service locally |
| 32 | `kubectl get ingress` | HTTP routing |
| 33 | `kubectl expose deployment <name> --port=80` | Create a Service |

> ⭐⭐ #29 is the highest-value networking command in Kubernetes. `<none>` means the problem is labels or readiness; populated means it's ports or policy.

---

## ⚙️ Configuration (34–38)

| # | Command | Why |
| --- | --- | --- |
| 34 | `kubectl get configmap <name> -o yaml` | Read config |
| 35 | `kubectl create configmap <name> --from-literal=<k>=<v>` | Create config |
| 36 | `kubectl get secret <name> -o jsonpath='{.data.<key>}' \| base64 -d` | Decode a secret ⚠️ leaks to scrollback |
| 37 | `kubectl create secret generic <name> --from-literal=<k>=<v>` | Create a secret |
| 38 | `kubectl exec <pod-name> -- env` | **What the container actually got** |

---

## 🐛 Troubleshooting (39–44)

| # | Command | Why |
| --- | --- | --- |
| 39 | `kubectl get events --sort-by=.lastTimestamp` | What just happened ⚠️ ~1h retention |
| 40 | `kubectl get pods -A \| grep -Ev 'Running\|Completed'` | Everything unhealthy, one screen ⭐ |
| 41 | `kubectl top pods` | CPU/memory `[needs Metrics Server]` |
| 42 | `kubectl top nodes` | Node pressure |
| 43 | `kubectl describe node <node-name>` | Capacity, taints, conditions |
| 44 | `kubectl debug -it <pod-name> --image=busybox --target=<container>` | Debug an image with no shell |

---

## 💾 Storage (45–46)

| # | Command | Why |
| --- | --- | --- |
| 45 | `kubectl get pvc` | Is storage bound? |
| 46 | `kubectl describe pvc <pvc-name>` | Why is it `Pending`? |

---

## 🔐 RBAC (47–48)

| # | Command | Why |
| --- | --- | --- |
| 47 | `kubectl auth can-i <verb> <resource>` | Am I allowed? |
| 48 | `kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa>` | **What can this workload do?** ⭐ |

---

## ⚡ Productivity (49–50)

| # | Command | Why |
| --- | --- | --- |
| 49 | `kubectl create deployment <n> --image=<i> --dry-run=client -o yaml` | Generate YAML |
| 50 | `kubectl explain <resource>.<field>` | The API docs, in your terminal |

---

## 📋 Copy-Paste Block

```bash
# Cluster
kubectl config current-context
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl cluster-info
kubectl get nodes -o wide

# Pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods -A
kubectl get pods -w
kubectl describe pod <pod-name>
kubectl delete pod <pod-name>

# Logs & shell
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl logs -f <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec <pod-name> -- env

# Deployments
kubectl get deployments
kubectl rollout status deployment/<deployment-name>
kubectl rollout restart deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl scale deployment/<deployment-name> --replicas=<n>
kubectl set image deployment/<deployment-name> <container>=<image>

# Networking
kubectl get svc
kubectl get svc -o wide
kubectl describe svc <service-name>
kubectl get endpoints <service-name>
kubectl get ingress
kubectl port-forward svc/<service-name> 8080:80
kubectl expose deployment <deployment-name> --port=80

# Config
kubectl get configmap <name> -o yaml
kubectl create configmap <name> --from-literal=<key>=<value>
kubectl create secret generic <name> --from-literal=<key>=<value>

# Troubleshooting
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'
kubectl get events --sort-by=.lastTimestamp
kubectl top pods
kubectl top nodes
kubectl describe node <node-name>
kubectl debug -it <pod-name> --image=busybox:1.36 --target=<container-name>

# Storage
kubectl get pvc
kubectl describe pvc <pvc-name>

# RBAC
kubectl auth can-i <verb> <resource>
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name>

# Productivity
kubectl apply -f <file>.yaml
kubectl create deployment <name> --image=<image> --dry-run=client -o yaml
kubectl explain <resource>.<field>
kubectl api-resources
```

---

## 🎯 If You Only Learn Four

```bash
kubectl get pods                          # find it
kubectl describe pod <pod-name>           # inspect it
kubectl logs <pod-name> --previous        # read what happened
kubectl exec -it <pod-name> -- /bin/sh    # go inside it
```

> **GET → DESCRIBE → LOGS → EXEC** solves most day-to-day Kubernetes problems.

---

## 🔗 Related

[Command Patterns](command-patterns.md) · [Interview Guide](interview-survival-guide.md) · [Scenarios](scenarios.md) · [Failure States](failure-states.md) · [One-Liners](kubectl-one-liners.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Command Patterns](command-patterns.md) | [README](../README.md) | [Failure States →](failure-states.md) |
