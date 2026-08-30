# 🧭 Troubleshooting Flow

**One page. Print it, pin it, follow it top to bottom.**

---

## ⚡ Triage — run these four first

```bash
kubectl config current-context                                # 1. right cluster?
kubectl get nodes                                             # 2. platform healthy?
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'    # 3. what's unhealthy?
kubectl get events -A --sort-by=.lastTimestamp | tail -30     # 4. what just happened?
```

> ⚠️ Events last ~1 hour. If the failure is older, they're gone.

---

## 🌳 The Decision Tree

```mermaid
flowchart TD
    S["🚨 Something is broken"] --> N["kubectl get nodes"]
    N --> N1{"All Ready?"}
    N1 -->|No| N2["Node problem — everything on it is affected<br/>kubectl describe node | grep -A6 Conditions"]
    N1 -->|Yes| P["kubectl get pods"]

    P --> Q{"STATUS?"}

    Q -->|Pending| A1["kubectl describe pod"]
    A1 --> A2["Events name it exactly:<br/>Insufficient cpu/memory · untolerated taint<br/>affinity mismatch · unbound PVC · quota"]

    Q -->|ContainerCreating| B1["kubectl describe pod"]
    B1 --> B2["FailedMount · Multi-Attach<br/>sandbox/CNI · missing ConfigMap"]

    Q -->|ImagePullBackOff| C1["kubectl describe pod"]
    C1 --> C2["Wrong tag · private registry<br/>no imagePullSecrets · rate limit"]

    Q -->|CrashLoopBackOff| D1["kubectl logs --previous ⭐"]
    D1 --> D2["Exit code:<br/>0=should be a Job · 1=app error<br/>127=cmd not found · 137=OOMKilled"]

    Q -->|"Running 0/1"| E1["kubectl describe pod | grep -i readiness"]
    E1 --> E2["Probe path/port · slow start<br/>bound to 127.0.0.1"]

    Q -->|"Running 1/1"| F1["kubectl logs"]
    F1 --> F2{"App healthy?"}
    F2 -->|No| F3["kubectl exec -it -- /bin/sh"]
    F2 -->|Yes| G1["kubectl get endpoints &lt;svc&gt; ⭐"]

    G1 --> G2{"Endpoints?"}
    G2 -->|"&lt;none&gt;"| G3["Selector mismatch or Pods not Ready"]
    G2 -->|Listed| G4["kubectl port-forward svc/&lt;svc&gt; 8080:80"]
    G4 --> G5{"Responds?"}
    G5 -->|No| G6["targetPort wrong · NetworkPolicy"]
    G5 -->|Yes| G7["kubectl get ingress<br/>empty ADDRESS=no controller<br/>404=host/path · 503=no endpoints<br/>works=DNS"]
```

---

## 📋 Layer Checklist

Work down. Stop at the first break.

### 1️⃣ Cluster

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes
kubectl describe node <node-name> | grep -A6 Conditions
```

✅ All nodes `Ready`, no `MemoryPressure` / `DiskPressure`.

### 2️⃣ Pod

```bash
kubectl get pods -o wide
kubectl describe pod <pod-name>
```

✅ `STATUS: Running`, `READY: 1/1`, `RESTARTS: 0`.
→ Anything else: [Failure States](failure-states.md)

### 3️⃣ Application

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- /bin/sh
```

✅ Logs show a healthy startup and no repeated errors.

### 4️⃣ Config

```bash
kubectl exec <pod-name> -- env | sort
kubectl exec <pod-name> -- ls -l /etc/config
kubectl get configmap,secret -n <namespace>
```

✅ The container has the values you expect.
> Changed a ConfigMap? `kubectl rollout restart deployment/<name>` — env vars never reload.

### 5️⃣ Network

```bash
kubectl get svc -o wide
kubectl get endpoints <service-name>      # ⭐ the pivot
kubectl port-forward pod/<pod-name> 8080:8080
kubectl port-forward svc/<service-name> 8080:80
kubectl get netpol -A
kubectl get ingress
```

✅ Endpoints populated, both port-forwards respond.

### 6️⃣ Resources

```bash
kubectl top pods --containers
kubectl top nodes
kubectl describe node <node-name> | grep -A10 "Allocated resources"
kubectl describe resourcequota -n <namespace>
```

✅ Under limits, node requests not fully committed.

### 7️⃣ Permissions

```bash
kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa> -n <ns>
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
```

✅ The workload's identity has what it needs — and the Pod is actually using it.

---

## 🎯 Symptom → Page

| Symptom | Go to |
| --- | --- |
| Pod won't start | [Failure States](failure-states.md) |
| Pod restarts constantly | [CrashLoopBackOff](failure-states.md#crashloopbackoff) |
| Can't reach the app | [Networking Mind Map](../mindmaps/networking-mindmap.md) |
| Deploy stuck | [04 · Deployments](../cheatsheets/04-deployments.md#-troubleshooting) |
| PVC `Pending` | [Storage Mind Map](../mindmaps/storage-mindmap.md) |
| `Forbidden` errors | [RBAC Mind Map](../mindmaps/rbac-mindmap.md) |
| App slow / OOM | [13 · Resource Management](../cheatsheets/13-resource-management.md) |
| Node `NotReady` | [14 · Node Operations](../cheatsheets/14-node-operations.md) |
| Ingress 404 / 503 | [09 · Ingress](../cheatsheets/09-ingress.md#-troubleshooting) |
| Helm release failed | [17 · Helm](../cheatsheets/17-helm-commands.md#-troubleshooting) |
| Scheduled job didn't run | [10 · Jobs & CronJobs](../cheatsheets/10-jobs-and-cronjobs.md#-troubleshooting) |
| EKS auth failure | [16 · EKS](../cheatsheets/16-eks-commands.md#-troubleshooting) |

---

## 🧩 The Chains

```text
POD       GET → DESCRIBE → LOGS → EXEC
DEPLOY    GET → DESCRIBE → ROLLOUT STATUS → PODS → LOGS
NETWORK   POD → SERVICE → ENDPOINTS → INGRESS → DNS
STORAGE   POD → PVC → PV → STORAGECLASS → CSI
RBAC      WHO → CAN-I → ROLE → BINDING
CONFIG    EXEC env → CONFIGMAP → SECRET → ROLLOUT RESTART
NODE      GET NODES → DESCRIBE NODE → CONDITIONS → TOP
```

---

## 🚑 Emergency Actions

> ⚠️ Confirm your context first: `kubectl config current-context`

```bash
# Roll back a bad deploy
kubectl rollout undo deployment/<deployment-name>

# Restart an app safely (gradual, probe-aware)
kubectl rollout restart deployment/<deployment-name>

# Scale up for load
kubectl scale deployment/<deployment-name> --replicas=<n>

# Stop new Pods landing on a sick node (safe, reversible)
kubectl cordon <node-name>

# Pause a misbehaving scheduled job
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":true}}'

# Capture evidence before it's cleaned up
kubectl logs <pod-name> --previous > incident.log
kubectl describe pod <pod-name> > incident-describe.txt
kubectl get events -A --sort-by=.lastTimestamp > incident-events.txt
```

> 💡 **Capture evidence before you fix.** Deleting the broken Pod makes the problem disappear and the cause unknowable.

---

## 🔗 Related

[12 · Debugging](../cheatsheets/12-debugging.md) · [Failure States](failure-states.md) · [Troubleshooting Mind Map](../mindmaps/troubleshooting-mindmap.md) · [Scenarios](scenarios.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Failure States](failure-states.md) | [README](../README.md) | [Scenarios →](scenarios.md) |
