# 📅 30-Day Command Plan

**One command family per day, grouped so each week builds on the last. Fifteen minutes a day on a real cluster.**

> 🎯 **Goal:** after 30 days you can navigate any Kubernetes cluster from the CLI without looking anything up.

**You need a cluster.** Minikube, Kind, Docker Desktop, or a small cloud cluster — all work.

```bash
kubectl version --client && kubectl cluster-info && kubectl get nodes
```

If those three work, you're ready.

---

## Week 1 — See and Understand

*By Sunday: you can find anything in a cluster and explain what you're looking at.*

| Day | Command | Practice | Read |
| --- | --- | --- | --- |
| **1** | `get` | `kubectl get pods`, `-o wide`, `-A`, `-w`. Read every column and know what it means. | [03 · Pods](../cheatsheets/03-pods.md) |
| **2** | `describe` | `kubectl describe pod <name>`. **Read it bottom-up.** Find the Events section on five different Pods. | [03 · Pods](../cheatsheets/03-pods.md) |
| **3** | `logs` | `logs`, `-f`, `--tail`, `--since`, `-c`. Deliberately break a Pod and read `--previous`. | [03 · Pods](../cheatsheets/03-pods.md) |
| **4** | `exec` | Get a shell in a Pod. Run `env`, `ls`, `cat`, `netstat`. Understand what `--` does. | [03 · Pods](../cheatsheets/03-pods.md) |
| **5** | contexts + namespaces | `config current-context`, `get-contexts`, `use-context`, `set-context --current --namespace=`. | [01](../cheatsheets/01-cluster-and-context.md) · [02](../cheatsheets/02-namespaces.md) |
| **6** | `explain` + `api-resources` | `kubectl explain pod.spec`. List every resource your cluster serves. | [15 · Productivity](../cheatsheets/15-kubectl-productivity.md) |
| **7** | 🔄 **Review** | Deploy nginx. Find it, describe it, read its logs, shell into it — without notes. | [Command Patterns](command-patterns.md) |

> 💡 **Day 7 checkpoint:** can you run `GET → DESCRIBE → LOGS → EXEC` from memory? That chain is the foundation for everything else.

---

## Week 2 — Create and Change

*By Sunday: you can deploy an application, update it, and roll it back.*

| Day | Command | Practice | Read |
| --- | --- | --- | --- |
| **8** | `run` + `create` | Create a Pod, a Deployment, a ConfigMap imperatively. | [04 · Deployments](../cheatsheets/04-deployments.md) |
| **9** | `--dry-run=client -o yaml` | Generate YAML for everything you made yesterday. Save the files. | [15 · Productivity](../cheatsheets/15-kubectl-productivity.md) |
| **10** | `apply` | Apply your generated files. Change a value, apply again. Notice it's idempotent. | [04 · Deployments](../cheatsheets/04-deployments.md) |
| **11** | `scale` + `set image` | Scale to 5 and back. Change the image. Watch Pods roll with `get pods -w`. | [04 · Deployments](../cheatsheets/04-deployments.md) |
| **12** | `rollout` | `status`, `history`, `restart`, `undo`. Deploy a **broken** image on purpose, then roll back. | [04 · Deployments](../cheatsheets/04-deployments.md) |
| **13** | `delete` + `diff` | `diff` before every apply. Delete by file, by name, by label. | [15 · Productivity](../cheatsheets/15-kubectl-productivity.md) |
| **14** | 🔄 **Review** | Full cycle: generate → apply → update → break → roll back. | [Scenarios](scenarios.md) |

> 💡 **Day 12 is the most valuable day of the month.** Deliberately breaking a deploy and recovering it teaches more than ten successful ones.

---

## Week 3 — Connect and Configure

*By Sunday: you can expose an application and understand why traffic does or doesn't reach it.*

| Day | Command | Practice | Read |
| --- | --- | --- | --- |
| **15** | `expose` + `get svc` | Expose a Deployment. Look at `-o wide` and find the selector. | [06 · Services](../cheatsheets/06-services.md) |
| **16** | `get endpoints` ⭐ | Break the selector on purpose. Watch endpoints go `<none>`. Fix it. | [06 · Services](../cheatsheets/06-services.md) |
| **17** | `port-forward` | Forward to a Pod, then to a Service. Understand why testing both is a bisection. | [06 · Services](../cheatsheets/06-services.md) |
| **18** | DNS | Run a busybox Pod. `nslookup` a Service by short name and by FQDN. | [Networking Mind Map](../mindmaps/networking-mindmap.md) |
| **19** | ConfigMaps | Create one, mount it as env and as a file. Change it — notice nothing happens until you restart. | [07](../cheatsheets/07-configmaps-and-secrets.md) |
| **20** | Secrets | Create one, decode it, and internalise that **base64 is not encryption**. | [07](../cheatsheets/07-configmaps-and-secrets.md) |
| **21** | 🔄 **Review** | Deploy an app + Service + ConfigMap. Reach it via port-forward. Break the selector and fix it from the endpoints. | [Networking Mind Map](../mindmaps/networking-mindmap.md) |

> 💡 **Day 16 is the highest-value single command in this plan.** `kubectl get endpoints` splits every networking problem in half for the rest of your career.

---

## Week 4 — Debug and Operate

*By Sunday: you can diagnose a broken cluster methodically.*

| Day | Command | Practice | Read |
| --- | --- | --- | --- |
| **22** | failure states | Deliberately create `ImagePullBackOff`, `CrashLoopBackOff`, and `Pending`. Diagnose each one. | [Failure States](failure-states.md) |
| **23** | `get events` | Sort by timestamp. Correlate events with the failures from Day 22. | [12 · Debugging](../cheatsheets/12-debugging.md) |
| **24** | resources | Set requests and limits. Cause an `OOMKilled` on purpose. Check `qosClass`. | [13](../cheatsheets/13-resource-management.md) |
| **25** | `top` | `top pods`, `top nodes`, `--sort-by`. Compare `top` against `describe node` allocated requests. | [13](../cheatsheets/13-resource-management.md) |
| **26** | storage | Create a PVC, mount it, write a file, delete the Pod, confirm the data survived. | [08 · Storage](../cheatsheets/08-storage.md) |
| **27** | RBAC | Create a ServiceAccount + Role + RoleBinding. Verify with `auth can-i --as=`. | [11 · RBAC](../cheatsheets/11-rbac.md) |
| **28** | nodes | `describe node`, `cordon`, `uncordon`. Dry-run a drain and read what it *would* evict. | [14](../cheatsheets/14-node-operations.md) |
| **29** | jobs + Helm | Run a Job and a CronJob. Install one chart with Helm and roll it back. | [10](../cheatsheets/10-jobs-and-cronjobs.md) · [17](../cheatsheets/17-helm-commands.md) |
| **30** | 🎓 **Final** | See the challenge below. | [Troubleshooting Flow](troubleshooting-flow.md) |

---

## 🎓 Day 30 — The Challenge

Do this from memory. Notes only if you're truly stuck.

```text
1.  Create a namespace and make it your default.
2.  Generate a Deployment manifest with --dry-run and apply it.
3.  Expose it with a Service.
4.  Add a ConfigMap and mount it as an environment variable.
5.  Confirm the container received it (kubectl exec -- env).
6.  Reach the app with port-forward.
7.  Deliberately break the Service selector.
8.  Diagnose it using ONLY kubectl get endpoints and describe. Fix it.
9.  Deploy a broken image tag. Diagnose from the Pod status alone.
10. Roll back.
11. Set a memory limit low enough to cause OOMKilled. Confirm via describe.
12. Fix the limit and verify with kubectl top.
13. Create a ServiceAccount with read-only Pod access; prove it with auth can-i --as=.
14. Cordon a node, dry-run a drain, read the output, uncordon.
15. Clean everything up by deleting the namespace.
```

**If you can do all fifteen without notes, you are comfortable operating Kubernetes from the CLI.**

---

## 🧠 What You Should Know By Day 30

**The chains, from memory:**

```text
POD       GET → DESCRIBE → LOGS → EXEC
DEPLOY    GET → DESCRIBE → ROLLOUT STATUS → PODS → LOGS
NETWORK   POD → SERVICE → ENDPOINTS → INGRESS → DNS
STORAGE   POD → PVC → PV → STORAGECLASS → CSI
RBAC      WHO → CAN-I → ROLE → BINDING
NODE      CORDON → DRAIN → PATCH → UNCORDON
```

**The grammar:**

```bash
kubectl <verb> <resource> <name> <flags>
```

**The three facts that matter most:**

1. `kubectl logs --previous` — the crashed container's output
2. `kubectl get endpoints` — splits every network problem in half
3. Scheduling uses **requests**, not usage — that's why an idle node can be full

---

## 🚀 After Day 30

| Next | Where |
| --- | --- |
| Interview preparation | [Interview Guide](interview-survival-guide.md) |
| Daily speed | [One-Liners](kubectl-one-liners.md) · shell completion |
| Cloud specifics | [16 · EKS](../cheatsheets/16-eks-commands.md) |
| Package management | [17 · Helm](../cheatsheets/17-helm-commands.md) |
| The concepts underneath | [k8s-concepts-visualized](https://github.com/cloud-prakhar/k8s-concepts-visualized) |
| Certification | CKA — heavily hands-on, and everything here is directly relevant |

---

## 💡 How To Actually Do This

**Fifteen minutes a day beats three hours on Sunday.** The commands need to become muscle memory, and that comes from repetition on different days.

**Break things on purpose.** Days 12 and 22 exist because you learn far more from diagnosing a failure you created than from a deploy that works.

**Type the commands out.** Copy-pasting teaches your clipboard, not you.

**Keep a personal file.** Every time you look something up twice, write it down. Your own notes beat any cheat sheet — including this one.

---

## 🔗 Related

[README](../README.md) · [Command Patterns](command-patterns.md) · [Top 50](top-50-kubectl-commands.md) · [Scenarios](scenarios.md) · [Interview Guide](interview-survival-guide.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Interview Guide](interview-survival-guide.md) | [README](../README.md) | [Examples →](../examples/README.md) |
