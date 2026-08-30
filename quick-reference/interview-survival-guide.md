# 🎓 Kubernetes Commands Interview Survival Guide

**20 commands every Kubernetes candidate should understand — with the question that gets asked about each one.**

> 🎯 Interviewers rarely ask "what does `kubectl get` do?" They ask you to *demonstrate a method*. Each entry below gives the command, why it matters, and the question it's really testing.

---

## 1. `kubectl get pods`

**Purpose:** List Pods and their status.

```bash
kubectl get pods -o wide
```

**Common question:** *"What do the READY and RESTARTS columns tell you?"*

> `READY` is ready-containers/total. `0/1` means the process started but the readiness probe is failing, so it's excluded from Service endpoints. `RESTARTS` above zero means containers have been crashing — and a Pod with age `10d` and 400 restarts has been broken for ten days.

---

## 2. `kubectl describe pod`

**Purpose:** Full detail plus the Events timeline.

```bash
kubectl describe pod <pod-name>
```

**Common question:** *"How do you find out why a Pod won't start?"*

> `describe`, and read it **bottom-up** — the Events section states the cause in plain English: `FailedScheduling`, `ImagePullBackOff`, `FailedMount`. Above it, `Last State` gives the exit code and reason of the previous container.

---

## 3. `kubectl logs --previous`

**Purpose:** Output from the container instance that crashed.

```bash
kubectl logs <pod-name> --previous
```

**Common question:** *"A Pod is in CrashLoopBackOff. What do you run?"*

> This one. The current container may have been alive two seconds and printed nothing — the evidence is in the run that died. Naming `--previous` unprompted is a strong signal you've actually done this.

---

## 4. `kubectl exec`

**Purpose:** Run a command inside a running container.

```bash
kubectl exec -it <pod-name> -- /bin/sh
```

**Common question:** *"What if the image has no shell?"*

> `kubectl debug -it <pod> --image=busybox --target=<container>` — an ephemeral container sharing the target's process namespace, stable since v1.25. That's the modern answer for distroless images.

---

## 5. `kubectl get endpoints`

**Purpose:** The Pod IPs actually behind a Service.

```bash
kubectl get endpoints <service-name>
```

**Common question:** *"Your Service returns nothing. Where do you look first?"*

> Here. `<none>` means no **Ready** Pod matched the selector — so the problem is labels or readiness. Populated endpoints means the problem is downstream: `targetPort`, NetworkPolicy, or the app. One command halves the search space.

---

## 6. `kubectl rollout status`

**Purpose:** Follow a deployment to completion.

```bash
kubectl rollout status deployment/<name> --timeout=5m
```

**Common question:** *"How does your pipeline know a deploy succeeded?"*

> It blocks until the rollout finishes and exits non-zero on failure or timeout — so CI fails properly instead of reporting green on a stuck rollout.

---

## 7. `kubectl rollout undo`

**Purpose:** Roll back to the previous revision.

```bash
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
```

**Common question:** *"How do you roll back, and what are its limits?"*

> It's fast because the old ReplicaSet still exists at zero replicas — rollback just scales it up. The limitation is what interviewers listen for: **it only reverts the Pod template.** Database migrations, ConfigMaps, and external state are untouched.

---

## 8. `kubectl rollout restart`

**Purpose:** Recreate all Pods using the rolling update strategy.

```bash
kubectl rollout restart deployment/<name>
```

**Common question:** *"How do you restart an application?"*

> Not by deleting Pods — a label-selector delete takes them all out at once. `rollout restart` replaces them gradually and respects readiness probes. It's also how you pick up a changed ConfigMap, since env vars never reload.

---

## 9. `kubectl scale`

**Purpose:** Change the replica count.

```bash
kubectl scale deployment/<name> --replicas=5
```

**Common question:** *"You scale a Deployment and it goes back. Why?"*

> An HPA is managing it. `kubectl get hpa` first — manual scaling on an autoscaled Deployment is reverted within a minute.

---

## 10. `kubectl apply -f`

**Purpose:** Declarative create-or-update.

```bash
kubectl apply -f <file>.yaml
```

**Common question:** *"`create` vs `apply` vs `replace`?"*

> `create` fails if the object exists. `apply` does a three-way merge against the last-applied config, so it's idempotent — the right choice for GitOps. `replace --force` deletes and recreates, which for a Deployment means every Pod goes at once.

---

## 11. `kubectl diff`

**Purpose:** Preview what `apply` would change.

```bash
kubectl diff -f <file>.yaml
```

**Common question:** *"How do you deploy safely to production?"*

> `diff` before `apply`, so you see the change before making it. It also answers "is what's running the same as what's in Git?" — exit code 1 means drift, which makes it useful in CI.

---

## 12. `kubectl auth can-i`

**Purpose:** Check permissions, including for another identity.

```bash
kubectl auth can-i --list --as=system:serviceaccount:<ns>:<sa> -n <ns>
```

**Common question:** *"An app gets 403 from the Kubernetes API. How do you debug it?"*

> Impersonate its ServiceAccount with `--as` to see what that identity actually has — then check `kubectl get pod -o jsonpath='{.spec.serviceAccountName}'` to confirm the Pod is even *using* it. Silently defaulting to `default` is a very common real cause.

---

## 13. `kubectl top`

**Purpose:** Live CPU and memory.

```bash
kubectl top pods --containers
kubectl top nodes
```

**Common question:** *"A Pod is Pending but `top` shows the node is idle. Why?"*

> Because scheduling is decided on **requests**, not usage. A node at 15% actual CPU can be unschedulable if requests are fully committed. Also worth noting: `top` needs Metrics Server, which isn't part of core Kubernetes.

---

## 14. `kubectl drain`

**Purpose:** Safely evacuate a node.

```bash
kubectl drain <node-name> --ignore-daemonsets --dry-run=client
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

**Common question:** *"Walk me through patching a node in production."*

> Check what's on it and what PDBs apply, dry-run the drain, confirm the rest of the cluster has capacity, then cordon → drain → patch → uncordon. If the drain hangs, that's a PodDisruptionBudget refusing further disruption — fix the app's availability rather than bypassing the budget.

---

## 15. `kubectl cordon` / `uncordon`

**Purpose:** Stop and resume scheduling on a node.

```bash
kubectl cordon <node-name>
```

**Common question:** *"Cordon vs drain vs taint?"*

> Cordon blocks new Pods and leaves running ones alone. Drain cordons *and* evicts. Taint is selective rather than blanket — it repels Pods without a matching toleration, which is how you dedicate nodes to particular workloads.

---

## 16. `kubectl get events`

**Purpose:** What Kubernetes recently did or failed to do.

```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -30
```

**Common question:** *"Why does describe show no events on a broken Pod?"*

> Events are retained for about an hour. If it's been failing since yesterday, there are none left — which is exactly why cluster event collection matters in production.

---

## 17. `kubectl explain`

**Purpose:** API documentation from the cluster itself.

```bash
kubectl explain deployment.spec.strategy.rollingUpdate
```

**Common question:** *"How do you find out what fields a resource supports?"*

> `explain` — it's the API reference for the exact version this cluster runs, and it works for CRDs, so it documents operators like cert-manager or Argo from the cluster itself.

---

## 18. `--dry-run=client -o yaml`

**Purpose:** Generate manifests instead of writing them.

```bash
kubectl create deployment web --image=nginx --dry-run=client -o yaml > deployment.yaml
```

**Common question:** *"How do you write a manifest for something new?"*

> Generate the skeleton from the cluster, then `kubectl explain` for anything unclear, then `kubectl diff` before applying. Copying YAML from a blog post gets you outdated API versions.

---

## 19. `kubectl port-forward`

**Purpose:** Tunnel a Pod or Service to your machine.

```bash
kubectl port-forward svc/<service-name> 8080:80
kubectl port-forward pod/<pod-name> 8080:8080
```

**Common question:** *"How do you test a Service with no Ingress?"*

> Port-forward. And the diagnostic use is better: forwarding to the **Pod** tests the Pod; forwarding to the **Service** tests the Pod *and* the selector. If Pod works and Service doesn't, the Service config is wrong. It's a bisection.

---

## 20. `kubectl config current-context`

**Purpose:** Which cluster am I about to affect?

```bash
kubectl config current-context
```

**Common question:** *"How do you avoid running commands against the wrong cluster?"*

> Check it before anything destructive, rename cloud-generated ARN contexts to human names, put the context in your shell prompt with `kube-ps1`, and keep production credentials in a separate `KUBECONFIG` rather than merged into your daily file. This is a *process* answer, and interviewers notice when a candidate has one.

---

## 🧠 The Concept Questions

Commands are half of it. These come up constantly.

| Question | The short answer |
| --- | --- |
| **Deployment vs ReplicaSet vs Pod?** | Pod runs containers. ReplicaSet keeps N alive. Deployment manages ReplicaSets for versioned, rollback-able updates. |
| **Deployment vs StatefulSet?** | StatefulSet when Pods aren't interchangeable — stable names, own volumes, ordered start/stop. Databases and clustered stores. |
| **What happens on a rolling update?** | A **new ReplicaSet** is created and scaled up while the old scales down, governed by `maxSurge`/`maxUnavailable`. The old one stays at 0 for rollback. |
| **How does a Service find Pods?** | Label selector → endpoints controller writes **Ready** Pod IPs into Endpoints/EndpointSlices → kube-proxy programs node rules. |
| **ClusterIP vs NodePort vs LoadBalancer?** | Layered, not alternatives. Each contains the previous. For HTTP, prefer one Ingress over many LoadBalancers. |
| **Ingress vs Service?** | Service is L4 for one app. Ingress is L7 routing across many. The Ingress object is inert — a **controller** must be installed. |
| **Request vs limit?** | Request = what the scheduler reserves. Limit = kernel ceiling. CPU over limit throttles; memory over limit OOMKills. |
| **QoS classes?** | Guaranteed (requests==limits), Burstable, BestEffort. BestEffort is evicted first. |
| **How do Secrets protect data?** | Barely, alone — base64 isn't encryption. Real protection is RBAC + encryption at rest + an external store. |
| **PV vs PVC vs StorageClass?** | PVC is the request, PV is the volume, StorageClass is the recipe for creating one dynamically. |
| **What happens when I delete a PVC?** | Depends on the PV's reclaim policy. `Delete` (the cloud default) destroys the disk. `Retain` keeps it. |
| **Explain RBAC.** | Role/ClusterRole define what; RoleBinding/ClusterRoleBinding attach it to subjects. Purely additive, no deny rules. |
| **RoleBinding→ClusterRole vs ClusterRoleBinding?** | The first grants those permissions **only in that namespace**. The second grants them everywhere. |
| **Job vs Deployment?** | Job runs to completion with a retry budget. A batch task in a Deployment becomes an infinite restart loop. |
| **What does Helm add over `kubectl apply`?** | Packaging, templating, and release history — `helm rollback` restores an entire previous state. |
| **eksctl vs aws eks vs kubectl?** | Build the infrastructure / manage the AWS resource / use the Kubernetes API. Knowing which owns a problem is the point. |

---

## ⚡ Five-Minute Revision

If you have five minutes, memorise these five chains:

```text
POD       GET → DESCRIBE → LOGS → EXEC
DEPLOY    GET → DESCRIBE → ROLLOUT STATUS → PODS → LOGS
NETWORK   POD → SERVICE → ENDPOINTS → INGRESS → DNS
STORAGE   POD → PVC → PV → STORAGECLASS → CSI
RBAC      WHO → CAN-I → ROLE → BINDING
```

Then three facts that get you further than most:

1. **`kubectl logs --previous`** — the crashed container's output
2. **`kubectl get endpoints`** — splits every network problem in half
3. **Scheduling uses requests, not usage** — why an idle node can be full

---

## 💡 What Interviewers Are Actually Testing

They are not checking whether you memorized flags. They want to see:

- **A method, not a list.** "I read the status, then describe, then the events" beats reciting twelve commands.
- **Honest limitations.** "Rollback only reverts the Pod template" shows you've done it in anger.
- **The right layer.** Knowing whether a problem is Pod, network, or AWS is most of the job.
- **Safety instincts.** Checking the context, dry-running a drain, capturing logs before deleting.

> The candidate who says *"I'd check `kubectl get endpoints` first, because that tells me whether the problem is above or below the Service"* is more convincing than the one who lists twenty commands.

---

## 🔗 Related

[Top 50 Commands](top-50-kubectl-commands.md) · [Failure States](failure-states.md) · [Command Patterns](command-patterns.md) · [Troubleshooting Flow](troubleshooting-flow.md) · [30-Day Plan](30-day-command-plan.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← One-Liners](kubectl-one-liners.md) | [README](../README.md) | [30-Day Plan →](30-day-command-plan.md) |
