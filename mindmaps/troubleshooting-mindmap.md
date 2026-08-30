# 🐛 Troubleshooting Mind Map

**One decision tree from "it's broken" to "I know why".**

---

## 🧠 The Method

Don't guess. **Narrow the layer**, one command per layer.

```text
1. THE POD?         Is it scheduled, started, alive, ready?
2. THE APP?         Is the process actually working?
3. THE NETWORK?     Service → Endpoints → Ingress → DNS
4. THE CONFIG?      ConfigMaps, Secrets, env, volumes
5. THE RESOURCES?   CPU, memory, quota, node capacity
6. THE PERMISSIONS? RBAC
```

Stop at the first layer that's broken. Everything below it is a symptom.

---

## 🌳 The Master Decision Tree

```mermaid
flowchart TD
    START["🚨 Something is broken"] --> T["kubectl get pods -A -o wide | grep -Ev 'Running|Completed'"]
    T --> N["kubectl get nodes"]
    N --> N1{"Any node NotReady?"}
    N1 -->|Yes| N2["Node problem first —<br/>everything on it is affected"]
    N1 -->|No| A["kubectl get pods"]

    A --> B{"STATUS?"}

    B -->|Pending| P1["kubectl describe pod"]
    P1 --> P2["Read Events:<br/>Insufficient cpu/memory<br/>untolerated taint<br/>unbound PVC<br/>exceeded quota"]

    B -->|ContainerCreating| C1["kubectl describe pod"]
    C1 --> C2["FailedMount · Multi-Attach<br/>sandbox/CNI · missing ConfigMap"]

    B -->|"ImagePullBackOff"| I1["kubectl describe pod"]
    I1 --> I2["Wrong tag · private registry<br/>missing imagePullSecrets · rate limit"]

    B -->|CrashLoopBackOff| K1["kubectl logs --previous"]
    K1 --> K2["kubectl describe pod | grep -A6 'Last State'"]
    K2 --> K3["Exit code:<br/>0 = should be a Job<br/>1 = app error<br/>127 = command not found<br/>137 = OOMKilled"]

    B -->|"Running 0/1"| R1["kubectl describe pod | grep -i readiness"]
    R1 --> R2["Probe path/port wrong<br/>app slower than initialDelay<br/>binds 127.0.0.1 not 0.0.0.0"]

    B -->|"Running 1/1"| S1["kubectl logs"]
    S1 --> S2{"App logs healthy?"}
    S2 -->|No| S3["kubectl exec -it -- /bin/sh<br/>(kubectl debug if no shell)"]
    S2 -->|Yes| NET["kubectl get endpoints &lt;svc&gt;"]

    NET --> NE{"Endpoints?"}
    NE -->|"&lt;none&gt;"| NE1["Selector mismatch,<br/>or Pods not Ready"]
    NE -->|Listed| NE2["kubectl port-forward svc/&lt;svc&gt; 8080:80"]
    NE2 --> NE3{"Responds?"}
    NE3 -->|No| NE4["targetPort wrong<br/>or NetworkPolicy blocking"]
    NE3 -->|Yes| ING["kubectl get ingress"]
    ING --> ING2["ADDRESS empty → no controller<br/>404 → path/host<br/>503 → no endpoints<br/>works → it's DNS"]
```

---

## ⚡ The 60-Second Triage

Run these four before anything else:

```bash
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'   # everything unhealthy
kubectl get nodes                                            # is the platform OK?
kubectl get events -A --sort-by=.lastTimestamp | tail -30    # what just happened
kubectl top nodes                                            # is anything starved?
```

> ⚠️ Events expire after **~1 hour**. A Pod broken since yesterday has none left — that's why `describe` on an old failure looks empty.

---

## 🎯 Status → First Command

| STATUS | Run this first |
| --- | --- |
| `Pending` | `kubectl describe pod <pod-name>` |
| `ContainerCreating` | `kubectl describe pod <pod-name>` |
| `ImagePullBackOff` | `kubectl describe pod <pod-name>` |
| `CrashLoopBackOff` | `kubectl logs <pod-name> --previous` |
| `Running 0/1` | `kubectl describe pod <pod-name> \| grep -i readiness` |
| `Running 1/1`, still broken | `kubectl get endpoints <service-name>` |
| `OOMKilled` | `kubectl describe pod <pod-name> \| grep -A5 "Last State"` |
| `Evicted` | `kubectl describe node <node-name> \| grep -A5 Conditions` |
| `Terminating` stuck | `kubectl get pod <pod-name> -o jsonpath='{.metadata.finalizers}'` |
| `Error` / `Completed` | `kubectl logs <pod-name> --previous` |

Full causes and fixes: **[Failure States](../quick-reference/failure-states.md)**

---

## 🌐 Network Sub-Tree

```mermaid
flowchart TD
    A["Can't reach the app"] --> B["kubectl get endpoints &lt;service&gt;"]
    B --> C{"Endpoints?"}
    C -->|"&lt;none&gt;"| D["kubectl get svc &lt;svc&gt; -o wide<br/>kubectl get pods --show-labels"]
    D --> E["Compare SELECTOR to Pod labels<br/>→ fix the mismatch"]
    C -->|"Listed"| F["kubectl port-forward pod/&lt;pod&gt; 8080:8080"]
    F --> G{"Pod responds?"}
    G -->|No| H["App isn't listening on that port"]
    G -->|Yes| I["kubectl port-forward svc/&lt;svc&gt; 8080:80"]
    I --> J{"Service responds?"}
    J -->|No| K["targetPort wrong →<br/>kubectl describe svc"]
    J -->|Yes| L["kubectl get netpol -A<br/>→ default-deny causes timeouts"]
    L --> M["kubectl get ingress<br/>→ ADDRESS / rules / TLS"]
    M --> N["nslookup from a test pod<br/>→ CoreDNS"]
```

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot --restart=Never -- /bin/bash
```

Inside: `nslookup <svc>.<ns>.svc.cluster.local` · `curl -v http://<svc>` · `nc -zv <pod-ip> <port>`

---

## 💾 Storage Sub-Tree

```mermaid
flowchart TD
    A["Volume problem"] --> B{"What's stuck?"}
    B -->|"PVC Pending"| C["kubectl describe pvc &lt;pvc&gt;"]
    C --> D["'waiting for first consumer' → ✅ normal<br/>'no volumes available' → check kubectl get sc<br/>'storageclass not found' → typo<br/>ProvisioningFailed → CSI driver / IAM"]
    B -->|"Pod ContainerCreating"| E["kubectl describe pod &lt;pod&gt;"]
    E --> F["Multi-Attach → RWO held by old Pod<br/>node affinity conflict → wrong AZ<br/>FailedMount timeout → CSI node driver"]
    B -->|"Disk full"| G["kubectl exec &lt;pod&gt; -- df -h"]
    G --> H["Expand: patch the PVC<br/>⚠️ volumes can only grow"]
```

---

## 📊 Resource Sub-Tree

```mermaid
flowchart TD
    A["Resource problem"] --> B{"Symptom?"}
    B -->|"Pending, node looks idle"| C["kubectl describe node | grep -A10 'Allocated resources'"]
    C --> D["⚠️ Scheduling uses REQUESTS, not usage.<br/>A node at 15% CPU can still be full."]
    B -->|OOMKilled| E["kubectl top pod --containers"]
    E --> F["Compare with the memory limit →<br/>raise it or fix the leak"]
    B -->|"Slow app"| G["kubectl top pod"]
    G --> H["CPU near limit → throttling.<br/>Raise or remove the CPU limit."]
    B -->|Evicted| I["kubectl get pod -o jsonpath='{.status.qosClass}'"]
    I --> J["BestEffort is evicted first →<br/>set requests and limits"]
```

---

## 🔐 RBAC Sub-Tree

```mermaid
flowchart TD
    A["Error: Forbidden"] --> B["Read it: WHO / VERB / RESOURCE / NAMESPACE"]
    B --> C["kubectl auth can-i &lt;verb&gt; &lt;resource&gt;<br/>--as=&lt;subject&gt; -n &lt;ns&gt;"]
    C --> D{"Says no?"}
    D -->|Yes| E["kubectl auth can-i --list --as=&lt;subject&gt;"]
    E --> F["Missing binding, or missing<br/>sub-resource like pods/log"]
    D -->|"Says yes"| G["kubectl get pod &lt;pod&gt;<br/>-o jsonpath='{.spec.serviceAccountName}'"]
    G --> H["Says 'default'? → Pod spec is<br/>missing serviceAccountName"]
```

---

## 🧠 Memory Chains

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

## 🔗 Related

| | |
| --- | --- |
| [12 · Debugging](../cheatsheets/12-debugging.md) | The full chapter with every command |
| [Failure States](../quick-reference/failure-states.md) | Lookup table for every Pod status |
| [Troubleshooting Flow](../quick-reference/troubleshooting-flow.md) | Printable one-pager |
| [Master Mind Map](kubectl-master-mindmap.md) | All commands, not just debugging |

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Master Mind Map](kubectl-master-mindmap.md) | [README](../README.md) | [Workload Mind Map →](workload-mindmap.md) |
