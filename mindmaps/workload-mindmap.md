# 🚀 Workload Mind Map

**Which workload type, and what happens underneath it.**

---

## 🌳 Choosing a Workload

```mermaid
flowchart TD
    A["What am I running?"] --> B{"Does it run forever?"}
    B -->|"No — runs and finishes"| C{"On a schedule?"}
    C -->|Yes| D["⏰ CRONJOB"]
    C -->|No| E["🔨 JOB"]
    B -->|Yes| F{"Needs stable identity<br/>or its own storage?"}
    F -->|Yes| G["🗄️ STATEFULSET<br/>+ headless Service<br/>+ volumeClaimTemplates"]
    F -->|No| H{"One copy on every node?"}
    H -->|Yes| I["🛰️ DAEMONSET"]
    H -->|No| J["✅ DEPLOYMENT<br/>(the default)"]

    J --> K["ReplicaSet"]
    K --> L["Pods"]
    G --> M["Pods 0..n, in order<br/>one PVC each"]
    I --> N["One Pod per eligible node"]
    E --> O["Pods until completions met"]
    D --> P["Job per tick → Pods"]
```

---

## 🧬 The Ownership Chain

```text
DEPLOYMENT              you write this
    │ creates one per revision
    ▼
REPLICASET              keeps N Pods alive
    │ creates
    ▼
POD                     you debug this
    │ contains
    ▼
CONTAINER(S)
```

```bash
kubectl get deploy,rs,pods -l app=<label-value>
```

See all three layers at once. During a rollout you'll see two ReplicaSets — the old one at 0 replicas is your rollback.

---

## 🔄 What a Rolling Update Actually Does

```text
Before:  ReplicaSet-v1 [███ 3]     ReplicaSet-v2 [   0]
During:  ReplicaSet-v1 [██  2]     ReplicaSet-v2 [█  1]
After:   ReplicaSet-v1 [    0]     ReplicaSet-v2 [███ 3]
                            ▲
                 kept — this is why rollback is instant
```

```bash
kubectl set image deployment/<name> <container>=<image>   # triggers it
kubectl rollout status deployment/<name>                  # watch it
kubectl rollout undo deployment/<name>                    # scale v1 back up
```

---

## 🗺️ Command Map by Workload

```mermaid
flowchart LR
    W(["WORKLOADS"])

    W --> D["DEPLOYMENT"]
    D --> D1["get deploy"]
    D --> D2["scale --replicas=n"]
    D --> D3["set image"]
    D --> D4["rollout status/history/undo/restart"]

    W --> S["STATEFULSET"]
    S --> S1["get sts"]
    S --> S2["scale (ordered)"]
    S --> S3["get pvc -l app=x"]
    S --> S4["delete --cascade=orphan"]

    W --> DS["DAEMONSET"]
    DS --> DS1["get ds -A"]
    DS --> DS2["rollout restart ds/x"]
    DS --> DS3["describe node | grep taint"]

    W --> J["JOB"]
    J --> J1["get jobs"]
    J --> J2["logs -l job-name=x"]
    J --> J3["wait --for=condition=complete"]

    W --> C["CRONJOB"]
    C --> C1["get cj"]
    C --> C2["create job --from=cronjob/x"]
    C --> C3["patch suspend true/false"]
```

---

## 📊 Comparison

| | Deployment | StatefulSet | DaemonSet | Job / CronJob |
| --- | --- | --- | --- | --- |
| Pod names | random | `<name>-0`, `-1` | random | random |
| Count | you set it | you set it | = eligible nodes | completions |
| Storage | shared / none | one PVC per Pod | usually hostPath | usually none |
| Start order | parallel | ordered `0→n` | per node | parallel |
| Per-Pod DNS | no | yes (headless Svc) | no | no |
| Scale to 0 | yes | yes | no | n/a |
| Use for | web, APIs | databases, Kafka | agents, CNI, CSI | batch, cron |

---

## 🐛 Workload Troubleshooting

```mermaid
flowchart TD
    A["Workload not working"] --> B{"Type?"}
    B -->|Deployment| C["kubectl rollout status deployment/&lt;name&gt;"]
    C --> D{"Stuck?"}
    D -->|"No Pods at all"| E["kubectl describe rs -l app=&lt;label&gt;<br/>← quota/webhook/RBAC errors land HERE"]
    D -->|"Pods unhealthy"| F["kubectl describe pod &lt;new-pod&gt;"]
    D -->|ProgressDeadlineExceeded| G["kubectl rollout undo deployment/&lt;name&gt;"]

    B -->|StatefulSet| H["kubectl get pods -l app=&lt;label&gt;"]
    H --> I["Stuck at Pod 0? → ordered startup<br/>Pending? → kubectl describe pvc"]

    B -->|DaemonSet| J["kubectl get ds -A"]
    J --> K["DESIRED &lt; node count? →<br/>describe node | grep taint"]

    B -->|"Job / CronJob"| L["kubectl get cronjob &lt;name&gt;"]
    L --> M["SUSPEND=True? ← check this first<br/>then: kubectl logs -l job-name=&lt;job&gt;"]
```

> 💡 **The single most useful workload debugging fact:** when a Deployment has zero Pods and no events, the rejection is recorded on the **ReplicaSet**, not the Deployment. `kubectl describe rs -l app=<label>`.

---

## 💡 Memory Trick

```text
DEPLOYMENT   →  "any three of these will do"    (cattle)
STATEFULSET  →  "I need db-0 specifically"      (pets, named)
DAEMONSET    →  "one on every machine"          (agents)
JOB          →  "run it, then stop"             (tasks)
CRONJOB      →  "run it at 2am"                 (scheduled tasks)
```

---

## 🔗 Related

[04 · Deployments](../cheatsheets/04-deployments.md) · [05 · Other Workloads](../cheatsheets/05-replicasets-and-other-workloads.md) · [10 · Jobs & CronJobs](../cheatsheets/10-jobs-and-cronjobs.md) · [03 · Pods](../cheatsheets/03-pods.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Troubleshooting Mind Map](troubleshooting-mindmap.md) | [README](../README.md) | [Networking Mind Map →](networking-mindmap.md) |
