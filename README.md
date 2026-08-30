# ☸️ Kubernetes Command Mind Map

**A visual Kubernetes command cheat sheet — kubectl, Helm, and EKS explained as mental models, not a command encyclopedia.**

> Don't memorize hundreds of kubectl commands.
> Learn the pattern behind them.

Kubernetes has thousands of possible command combinations. Nobody remembers them. What experienced engineers actually carry in their head is a **grammar** and a handful of **workflows**. This repo teaches those.

---

## 🧭 Quick Navigation

**"I want to…"**

| I want to... | Go here |
| --- | --- |
| Understand how kubectl commands are built | [Command Patterns](quick-reference/command-patterns.md) |
| Find any command from a picture | [Master Mind Map](mindmaps/kubectl-master-mindmap.md) |
| Connect to a cluster / switch context | [01 · Cluster & Context](cheatsheets/01-cluster-and-context.md) |
| Work inside a namespace | [02 · Namespaces](cheatsheets/02-namespaces.md) |
| Inspect Pods | [03 · Pods](cheatsheets/03-pods.md) |
| Deploy and roll out applications | [04 · Deployments](cheatsheets/04-deployments.md) |
| Use StatefulSets / DaemonSets / ReplicaSets | [05 · Other Workloads](cheatsheets/05-replicasets-and-other-workloads.md) |
| Expose applications | [06 · Services](cheatsheets/06-services.md) |
| Manage configuration and secrets | [07 · ConfigMaps & Secrets](cheatsheets/07-configmaps-and-secrets.md) |
| Manage storage | [08 · Storage](cheatsheets/08-storage.md) |
| Route HTTP traffic | [09 · Ingress](cheatsheets/09-ingress.md) |
| Run batch and scheduled work | [10 · Jobs & CronJobs](cheatsheets/10-jobs-and-cronjobs.md) |
| Check permissions | [11 · RBAC](cheatsheets/11-rbac.md) |
| **Debug a broken application** | [12 · Debugging](cheatsheets/12-debugging.md) |
| Manage CPU / memory / quotas | [13 · Resource Management](cheatsheets/13-resource-management.md) |
| Drain or maintain a node | [14 · Node Operations](cheatsheets/14-node-operations.md) |
| Work faster with kubectl | [15 · kubectl Productivity](cheatsheets/15-kubectl-productivity.md) |
| Manage AWS EKS | [16 · EKS Commands](cheatsheets/16-eks-commands.md) |
| Manage packages | [17 · Helm](cheatsheets/17-helm-commands.md) |
| Look up a Pod failure state | [Failure States](quick-reference/failure-states.md) |
| Revise before an interview | [Top 50 Commands](quick-reference/top-50-kubectl-commands.md) · [Interview Guide](quick-reference/interview-survival-guide.md) |
| Solve a real task right now | [Scenarios: "What command do I use?"](quick-reference/scenarios.md) |
| Learn this properly over a month | [30-Day Command Plan](quick-reference/30-day-command-plan.md) |

---

## 🧠 The One Thing To Learn First

Almost every kubectl command follows one shape:

```bash
kubectl <verb> <resource> <name> <flags>
```

| Part | Means | Example |
| --- | --- | --- |
| `verb` | What do you want to do? | `get`, `describe`, `delete` |
| `resource` | What kind of object? | `pods`, `deployments`, `services` |
| `name` | Which specific one? *(optional)* | `nginx` |
| `flags` | Modify the behavior | `-n prod`, `-o wide` |

So these are not three commands to memorize — they are **one pattern, three fillings**:

```bash
kubectl get pods
kubectl describe pod nginx
kubectl delete pod nginx
```

Once the pattern clicks, `kubectl describe statefulset my-db` is something you can *derive*, not recall.

👉 Full treatment: **[Command Patterns — the cheat code](quick-reference/command-patterns.md)**

---

## The Verbs

What you can *do*:

```text
INSPECT            CHANGE             TROUBLESHOOT       ADMIN
  get                create             logs               cordon
  describe           apply              exec               drain
  explain            edit               events             uncordon
                     patch              top                taint
                     replace            debug
                     scale              port-forward
                     set
                     rollout
                     delete             label / annotate   expose
```

## The Resources

What you can act *on* (the most common ones):

```text
WORKLOADS          NETWORKING         CONFIG             STORAGE          CLUSTER          SECURITY
  pods               services           configmaps         persistentvolumes    nodes         serviceaccounts
  deployments        endpoints          secrets            persistentvolumeclaims  namespaces roles
  replicasets        ingress                               storageclasses       events        rolebindings
  statefulsets       ingressclasses                                                          clusterroles
  daemonsets         networkpolicies                                                         clusterrolebindings
  jobs
  cronjobs
```

Don't memorize this list. Run:

```bash
kubectl api-resources
```

That prints every resource your cluster actually supports, with its short name and API group. It is the authoritative version of the table above.

---

## 🗺️ The Mental Model

Every kubectl command you will ever type belongs to one of five intents:

```text
kubectl
   │
   ├── 🔍 SEE IT
   │     ├── get         → list objects
   │     ├── describe    → deep detail + events
   │     └── explain     → what fields exist (docs in your terminal)
   │
   ├── 🚀 CREATE / CHANGE IT
   │     ├── create      → make it now (imperative)
   │     ├── apply       → make the cluster match this file (declarative)
   │     ├── edit        → open the live object in your editor
   │     ├── patch       → surgically change one field
   │     ├── scale       → change replica count
   │     └── set image   → change a container image
   │
   ├── 🐛 TROUBLESHOOT IT
   │     ├── logs        → what did the app print?
   │     ├── exec        → get a shell inside it
   │     ├── events      → what did Kubernetes try to do?
   │     ├── top         → how much CPU/memory is it using?
   │     └── debug       → attach a debug container to it
   │
   ├── 🌐 CONNECT TO IT
   │     ├── expose        → create a Service for it
   │     ├── port-forward  → tunnel it to your laptop
   │     └── get endpoints → is the Service actually wired to Pods?
   │
   └── 🗑️ REMOVE IT
         └── delete      → ⚠️ destroy it
```

👉 The full, expanded version: **[Master Mind Map](mindmaps/kubectl-master-mindmap.md)**

---

## 💡 The Four-Command Chain

If you remember nothing else from this repository, remember this:

```text
GET  →  DESCRIBE  →  LOGS  →  EXEC
```

> **Find it → Inspect it → Read what happened → Go inside it.**

```bash
kubectl get pods                          # 1. Find it. Is it even running?
kubectl describe pod <pod-name>           # 2. Inspect it. What did Kubernetes do?
kubectl logs <pod-name>                   # 3. Read it. What did the app say?
kubectl exec -it <pod-name> -- /bin/sh    # 4. Enter it. Poke around inside.
```

This single chain solves the majority of day-to-day Kubernetes problems. Everything else in this repo is a variation on it.

More chains for networking, storage, and RBAC: **[Command Memory Chains](quick-reference/command-patterns.md#-command-memory-chains)**

---

## 🏷️ Short Names — Type Less

| Resource | Short | Resource | Short |
| --- | --- | --- | --- |
| `pods` | `po` | `persistentvolumeclaims` | `pvc` |
| `deployments` | `deploy` | `persistentvolumes` | `pv` |
| `replicasets` | `rs` | `storageclasses` | `sc` |
| `statefulsets` | `sts` | `serviceaccounts` | `sa` |
| `daemonsets` | `ds` | `ingresses` | `ing` |
| `services` | `svc` | `ingressclasses` | *(none)* |
| `namespaces` | `ns` | `networkpolicies` | `netpol` |
| `configmaps` | `cm` | `nodes` | `no` |
| `secrets` | *(none)* | `events` | `ev` |
| `cronjobs` | `cj` | `jobs` | *(none)* |
| `horizontalpodautoscalers` | `hpa` | `customresourcedefinitions` | `crd` |
| `resourcequotas` | `quota` | `limitranges` | `limits` |

Get the authoritative list for **your** cluster — including CRDs installed by operators:

```bash
kubectl api-resources
```

> 💡 Short names work everywhere a full name works: `kubectl get po`, `kubectl describe deploy nginx`, `kubectl delete svc web`.

---

## 🔀 Imperative vs Declarative

Two ways to change a cluster. Both are valid; they are for different jobs.

**Imperative — "do this now":**

```bash
kubectl create deployment nginx --image=nginx
kubectl scale deployment nginx --replicas=3
```

**Declarative — "make the cluster look like this":**

```bash
kubectl apply -f deployment.yaml
```

| | Imperative | Declarative |
| --- | --- | --- |
| Reads like | A command | A description of the desired state |
| Repeatable? | Second run fails (already exists) | Second run is a no-op — safe |
| Reviewable? | Only in shell history | Yes — it's a file in Git |
| Best for | Learning, quick tests, one-off fixes | **Production, GitOps, anything real** |

> 💡 **Recommendation:** use imperative commands to *learn* and to *generate YAML*, then commit that YAML and use `kubectl apply` for everything that matters. See [dry-run generation](cheatsheets/15-kubectl-productivity.md#-generate-yaml-without-writing-yaml).

---

## 🏷️ How To Read This Repository

**Difficulty labels** appear next to commands:

| Label | Means |
| --- | --- |
| 🟢 **Beginner** | Safe, read-only or low-impact. Learn these first. |
| 🟡 **Intermediate** | Needs a concept behind it, or changes live state in a recoverable way. |
| 🔴 **Advanced** | Conceptually deep **or** high blast radius. Understand before running. |

Difficulty is scored on *conceptual complexity and blast radius* — never on how long the command is.

**Safety callouts:**

> ⚠️ **Production Impact** — appears before any command that can destroy, disrupt, or degrade a running system. The callout always explains *what it affects* before showing the command.

**Platform tags** appear inline only where behavior genuinely differs:
`[EKS]` `[AKS]` `[GKE]` `[kubeadm]` `[minikube/kind]`

**Dependency tags** flag commands that need an optional cluster component:
`[needs Metrics Server]` `[needs Ingress Controller]` `[needs CSI driver]`

Everything untagged works the same on EKS, AKS, GKE, kubeadm, Kind, Minikube, and Docker Desktop.

**Placeholders** are always angle-bracketed: `<pod-name>`, `<namespace>`, `<deployment-name>`. Replace the whole thing, brackets included.

---

## 📚 Repository Contents

### Cheat sheets — learn an area properly

| # | File | Covers |
| --- | --- | --- |
| 01 | [Cluster & Context](cheatsheets/01-cluster-and-context.md) | `cluster-info`, nodes, kubeconfig, contexts |
| 02 | [Namespaces](cheatsheets/02-namespaces.md) | Creating, switching, scoping |
| 03 | [Pods](cheatsheets/03-pods.md) | get, describe, logs, exec, port-forward, selectors |
| 04 | [Deployments](cheatsheets/04-deployments.md) | scale, set image, the whole `rollout` family |
| 05 | [Other Workloads](cheatsheets/05-replicasets-and-other-workloads.md) | ReplicaSets, StatefulSets, DaemonSets |
| 06 | [Services](cheatsheets/06-services.md) | ClusterIP, NodePort, LoadBalancer, ExternalName, endpoints |
| 07 | [ConfigMaps & Secrets](cheatsheets/07-configmaps-and-secrets.md) | Creating, reading, decoding, secret types |
| 08 | [Storage](cheatsheets/08-storage.md) | PV, PVC, StorageClass, CSI |
| 09 | [Ingress](cheatsheets/09-ingress.md) | Ingress, IngressClass, controllers |
| 10 | [Jobs & CronJobs](cheatsheets/10-jobs-and-cronjobs.md) | Batch and scheduled workloads |
| 11 | [RBAC](cheatsheets/11-rbac.md) | `auth can-i`, roles, bindings, service accounts |
| 12 | [Debugging](cheatsheets/12-debugging.md) | **The flagship** — the full troubleshooting workflow |
| 13 | [Resource Management](cheatsheets/13-resource-management.md) | requests/limits, `top`, quotas, LimitRange |
| 14 | [Node Operations](cheatsheets/14-node-operations.md) | cordon, drain, uncordon, taints |
| 15 | [kubectl Productivity](cheatsheets/15-kubectl-productivity.md) | dry-run, explain, output formats, labels, diff, wait |
| 16 | [EKS Commands](cheatsheets/16-eks-commands.md) | `aws eks`, `eksctl`, IRSA, add-ons |
| 17 | [Helm](cheatsheets/17-helm-commands.md) | repos, install, upgrade, rollback, template |

### Mind maps — find a command from a picture

| Map | Answers |
| --- | --- |
| [kubectl Master](mindmaps/kubectl-master-mindmap.md) | "Which kubectl command should I use?" |
| [Troubleshooting](mindmaps/troubleshooting-mindmap.md) | "It's broken — what now?" |
| [Workloads](mindmaps/workload-mindmap.md) | Deployment → ReplicaSet → Pod, and which workload type to pick |
| [Networking](mindmaps/networking-mindmap.md) | User → Ingress → Service → Endpoints → Pod |
| [Storage](mindmaps/storage-mindmap.md) | Pod → PVC → PV → StorageClass → CSI |
| [RBAC](mindmaps/rbac-mindmap.md) | Who → can do what → bound how |
| [Cluster Admin](mindmaps/cluster-admin-mindmap.md) | Node lifecycle and maintenance |
| [Helm](mindmaps/helm-mindmap.md) | Repo → Chart → Release → Resources |

### Quick reference — answers in seconds

| Page | Use when |
| --- | --- |
| [Command Patterns](quick-reference/command-patterns.md) | You want to stop memorizing and start deriving |
| [Top 50 Commands](quick-reference/top-50-kubectl-commands.md) | You have 5 minutes before an interview |
| [Troubleshooting Flow](quick-reference/troubleshooting-flow.md) | Something is broken and you need a decision tree |
| [Failure States](quick-reference/failure-states.md) | A Pod shows a status you don't recognize |
| [Scenarios](quick-reference/scenarios.md) | You know the goal, not the command |
| [One-Liners](quick-reference/kubectl-one-liners.md) | You need a sharp jsonpath / sort / filter |
| [Interview Guide](quick-reference/interview-survival-guide.md) | You're preparing for an interview |
| [30-Day Plan](quick-reference/30-day-command-plan.md) | You want a structured path from zero to fluent |

### Examples

Minimal, working manifests in [`examples/`](examples/) — each one paired with the `--dry-run=client` command that generates it, so you learn to produce them yourself.

---

## 🚀 Suggested Path

**Brand new to Kubernetes?**

```text
Command Patterns → 03 Pods → 02 Namespaces → 04 Deployments → 06 Services → 12 Debugging
```

**Already using Kubernetes, want fluency?**

```text
Master Mind Map → 12 Debugging → 15 Productivity → 13 Resource Management → 14 Node Operations
```

**Interview in a week?**

```text
Top 50 Commands → Interview Guide → Failure States → Troubleshooting Flow
```

**Have 30 days?** → [30-Day Command Plan](quick-reference/30-day-command-plan.md)

---

## 🔧 Prerequisites

You need a cluster and `kubectl`. Any of these work with everything here:

| Option | Best for |
| --- | --- |
| **Minikube** / **Kind** | Learning on a laptop, free |
| **Docker Desktop** (Kubernetes enabled) | Easiest local setup |
| **kubeadm** | Understanding the control plane |
| **EKS / AKS / GKE** | Real production work |

Check you're connected:

```bash
kubectl version --client     # is kubectl installed?
kubectl cluster-info         # am I talking to a cluster?
kubectl get nodes            # is the cluster healthy?
```

If those three work, everything in this repository will work.

---

## 🔗 Related

- **[k8s-concepts-visualized](https://github.com/cloud-prakhar/k8s-concepts-visualized)** — the *concepts* companion to this repo. This repo teaches the commands; that one teaches why Kubernetes works the way it does. Where theory would bloat a command page here, it links there.
- [Official kubectl reference](https://kubernetes.io/docs/reference/kubectl/)
- [Official kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| — | [README](README.md) | [Master Mind Map →](mindmaps/kubectl-master-mindmap.md) |
