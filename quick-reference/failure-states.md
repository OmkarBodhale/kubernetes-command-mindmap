# 🚨 Failure States

**Every Pod status you'll see, what it means, and what to run. The 2am lookup page.**

---

## ⚡ Fast Index

| Status | First command |
| --- | --- |
| [`Pending`](#pending) | `kubectl describe pod <pod-name>` |
| [`ContainerCreating`](#containercreating) | `kubectl describe pod <pod-name>` |
| [`ImagePullBackOff` / `ErrImagePull`](#imagepullbackoff--errimagepull) | `kubectl describe pod <pod-name>` |
| [`CrashLoopBackOff`](#crashloopbackoff) | `kubectl logs <pod-name> --previous` |
| [`Running` but `0/1`](#running-but-not-ready) | `kubectl describe pod <pod-name>` |
| [`OOMKilled`](#oomkilled) | `kubectl describe pod <pod-name> \| grep -A5 "Last State"` |
| [`Evicted`](#evicted) | `kubectl describe node <node-name>` |
| [`CreateContainerConfigError`](#createcontainerconfigerror) | `kubectl describe pod <pod-name>` |
| [`CreateContainerError`](#createcontainererror) | `kubectl describe pod <pod-name>` |
| [`Init:Error` / `Init:CrashLoopBackOff`](#initerror--initcrashloopbackoff) | `kubectl logs <pod-name> -c <init-container>` |
| [`Terminating`](#terminating-stuck) | `kubectl get pod <pod-name> -o jsonpath='{.metadata.finalizers}'` |
| [`Completed`](#completed) | `kubectl logs <pod-name>` |
| [`Error`](#error) | `kubectl logs <pod-name> --previous` |
| [`Unknown`](#unknown) | `kubectl get nodes` |

---

## `Pending`

**Meaning:** The Pod object exists but the scheduler hasn't placed it on a node.

**Likely causes:**
- No node has enough uncommitted CPU or memory (based on **requests**, not usage)
- Taints on every node that the Pod doesn't tolerate
- `nodeSelector` or `nodeAffinity` matches nothing
- Its PVC is unbound
- Namespace ResourceQuota exceeded
- All nodes cordoned

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -A10 Events
kubectl describe node <node-name> | grep -A10 "Allocated resources"
kubectl get nodes
kubectl describe pvc <pvc-name>
kubectl describe resourcequota -n <namespace>
```

**What to inspect:** the `FailedScheduling` event — it names the reason precisely.

| Event text | Cause |
| --- | --- |
| `Insufficient cpu` / `Insufficient memory` | Node capacity, by requests |
| `node(s) had untolerated taint` | Taints |
| `didn't match Pod's node affinity/selector` | Labels don't match |
| `pod has unbound immediate PersistentVolumeClaims` | Storage |
| `node(s) had volume node affinity conflict` | Volume in another AZ |
| `exceeded quota` | Namespace quota |

> 💡 Scheduling uses **requests**, not actual usage. A node at 15% CPU can be unschedulable. → [13 · Resource Management](../cheatsheets/13-resource-management.md)

---

## `ContainerCreating`

**Meaning:** Scheduled onto a node; the kubelet is setting it up. Normal for a few seconds — a problem after a minute.

**Likely causes:** volume attach/mount failure · CNI/sandbox failure · missing ConfigMap or Secret · slow image pull

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -A10 Events
kubectl get events --field-selector involvedObject.name=<pod-name>
```

| Event | Cause | Go to |
| --- | --- | --- |
| `FailedMount` / `timeout expired waiting for volumes` | Storage | [08](../cheatsheets/08-storage.md) |
| `Multi-Attach error for volume` | RWO volume held by another node | [08](../cheatsheets/08-storage.md) |
| `failed to create pod sandbox` | CNI plugin | [12](../cheatsheets/12-debugging.md) |
| `secret "x" not found` | Missing Secret | [07](../cheatsheets/07-configmaps-and-secrets.md) |

---

## `ImagePullBackOff` / `ErrImagePull`

**Meaning:** The kubelet cannot pull the image. `ErrImagePull` is the first failure; `ImagePullBackOff` is the retry backoff.

**Likely causes:** wrong image name or tag · private registry without credentials · registry unreachable · Docker Hub rate limit · architecture mismatch

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -A5 Events
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'
kubectl get pod <pod-name> -o jsonpath='{.spec.imagePullSecrets}'
```

| Event | Cause | Fix |
| --- | --- | --- |
| `manifest for X not found` | Tag doesn't exist | Check the tag — usually a typo |
| `pull access denied` / `unauthorized` | Private registry | Add `imagePullSecrets` |
| `no such host` | Bad registry hostname / DNS | Check the image reference |
| `toomanyrequests` | Docker Hub rate limit | Authenticate or mirror |
| `x509: certificate signed by unknown authority` | Self-signed registry cert | Trust the CA on nodes |
| `no matching manifest for linux/arm64` | Wrong architecture | Multi-arch image, or match node arch |

**What to inspect:** print the image string and read it character by character. The fault is usually visible.

---

## `CrashLoopBackOff`

**Meaning:** The container starts, exits, and Kubernetes restarts it with increasing backoff (10s → 20s → 40s → … → 5min cap).

> This is **not** a Kubernetes error. Your container is exiting.

**Likely causes:**
1. Missing or wrong config / env var
2. Can't reach a dependency at startup
3. Memory limit too low (check for `OOMKilled`)
4. Wrong `command`/`args` (exit 127)
5. Liveness probe killing a slow-starting app
6. A one-shot task deployed as a Deployment (exit 0)

**Commands:**

```bash
kubectl logs <pod-name> --previous              # ⭐ the answer is usually here
kubectl describe pod <pod-name> | grep -A10 "Last State"
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].livenessProbe}'
```

**Exit codes:**

| Code | Means |
| --- | --- |
| `0` | Exited cleanly — should this be a Job? |
| `1` | Application error — read the logs |
| `126` | Command found but not executable |
| `127` | **Command not found** — bad args or wrong image |
| `137` | SIGKILL — almost always **OOMKilled** |
| `139` | SIGSEGV — segfault |
| `143` | SIGTERM — graceful termination |

**What to inspect:** `--previous` logs first, then the exit code, then the probes.

---

## `Running` but not Ready

**Meaning:** `READY 0/1` with `STATUS Running`. The process started; the **readiness probe** is failing, so Kubernetes keeps it out of Service endpoints.

**Likely causes:** wrong probe path or port · app slower to start than `initialDelaySeconds` · health endpoint depends on a broken dependency · app bound to `127.0.0.1` instead of `0.0.0.0`

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -i -A5 readiness
kubectl describe pod <pod-name> | grep -i unhealthy
kubectl exec <pod-name> -- wget -qO- http://localhost:8080/healthz
kubectl exec <pod-name> -- netstat -tlnp
```

**What to inspect:** the `Unhealthy` event states the probe type and the response it got.

> 💡 This is also why a Service shows `Endpoints: <none>` — only **Ready** Pods are included. Working as designed.

---

## `OOMKilled`

**Meaning:** The container exceeded its memory **limit** and the kernel killed it. Appears as `Reason: OOMKilled`, exit code 137.

**Likely causes:** limit set too low · memory leak · a JVM/Node.js runtime ignoring cgroup limits · a genuine load spike

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -B2 -A5 "Last State"
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].resources}'
kubectl top pod <pod-name> --containers
```

**What to inspect:** the limit vs actual usage. Then decide: raise the limit, or fix the leak.

> 💡 `kubectl top` is an instantaneous sample — a Pod killed by a five-second spike looks healthy in it. Set the runtime's own heap ceiling below the container limit. → [13](../cheatsheets/13-resource-management.md)

---

## `Evicted`

**Meaning:** The node was under memory or disk pressure and the kubelet evicted Pods to recover.

**Likely causes:** node out of memory · node disk full · `BestEffort` QoS (evicted first)

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -i message
kubectl describe node <node-name> | grep -A5 Conditions
kubectl get pod <pod-name> -o jsonpath='{.status.qosClass}'
kubectl get pods -A --field-selector status.phase=Failed
```

**Cleanup after fixing the cause:**

```bash
kubectl delete pods -A --field-selector status.phase=Failed
```

**What to inspect:** node `MemoryPressure`/`DiskPressure`, and the Pod's QoS class. `BestEffort` Pods are evicted first — set requests and limits. → [13](../cheatsheets/13-resource-management.md)

---

## `CreateContainerConfigError`

**Meaning:** The Pod references a ConfigMap, Secret, or key that doesn't exist.

**Commands:**

```bash
kubectl describe pod <pod-name>       # the event names the missing object
kubectl get configmap,secret -n <namespace>
kubectl describe configmap <name>     # does the KEY exist?
```

**What to inspect:** ConfigMaps and Secrets are **namespaced** — a Pod cannot reference one in another namespace. That's a frequent cause. → [07](../cheatsheets/07-configmaps-and-secrets.md)

---

## `CreateContainerError`

**Meaning:** The container runtime couldn't create the container — distinct from a config problem.

**Likely causes:** the `command` doesn't exist in the image · a mount path conflict · SELinux/AppArmor denial · a `securityContext` the runtime rejects

**Commands:**

```bash
kubectl describe pod <pod-name> | grep -A10 Events
kubectl get pod <pod-name> -o yaml | grep -A10 securityContext
```

---

## `Init:Error` / `Init:CrashLoopBackOff`

**Meaning:** An **init container** failed. The main containers never start — init containers must complete successfully first, in order.

**Commands:**

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.initContainers[*].name}'
kubectl logs <pod-name> -c <init-container-name>
kubectl logs <pod-name> -c <init-container-name> --previous
kubectl describe pod <pod-name>
```

**What to inspect:** the init container's own logs — **you must pass `-c`**, or you get an error about needing a container name. Common causes are a dependency wait-loop that never succeeds, or a migration that fails.

---

## `Terminating` (stuck)

**Meaning:** Deletion requested but not finished.

**Likely causes:** a **finalizer** nothing is clearing · a `preStop` hook that never returns · a long `terminationGracePeriodSeconds` · the node is unreachable

**Commands:**

```bash
kubectl get pod <pod-name> -o jsonpath='{.metadata.finalizers}'
kubectl describe pod <pod-name>
kubectl get nodes
```

> ⚠️ `kubectl delete pod <name> --grace-period=0 --force` removes it from the API **without confirming the containers stopped**. For a StatefulSet that risks two Pods with the same identity writing to one volume — data corruption. Only use it when the node is confirmed gone.

---

## `Completed`

**Meaning:** The container exited with code 0. **Correct** for a Job; **wrong** for a Deployment.

**Commands:**

```bash
kubectl logs <pod-name>
kubectl get pod <pod-name> -o jsonpath='{.metadata.ownerReferences[*].kind}'
```

**What to inspect:** what owns it. If a Deployment owns a `Completed` Pod, the workload is a batch task and should be a Job. → [10](../cheatsheets/10-jobs-and-cronjobs.md)

---

## `Error`

**Meaning:** The container exited non-zero and isn't being restarted (usually `restartPolicy: Never`, typical of Jobs).

**Commands:**

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name> | grep -A6 "Last State"
```

---

## `Unknown`

**Meaning:** The API server has lost contact with the node running this Pod.

**Commands:**

```bash
kubectl get nodes
kubectl describe node <node-name> | grep -A10 Conditions
```

**What to inspect:** the node, not the Pod. After ~5 minutes of `NotReady`, Kubernetes applies `node.kubernetes.io/unreachable:NoExecute` and Pods are rescheduled elsewhere automatically. → [14](../cheatsheets/14-node-operations.md)

---

## 🔎 Find Everything Unhealthy

```bash
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'
kubectl get pods -A --field-selector status.phase=Failed
kubectl get pods -A --field-selector status.phase=Pending
kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount | tail -20
kubectl get events -A --sort-by=.lastTimestamp | tail -30
```

> ⚠️ Events are retained for **~1 hour**. A failure from yesterday leaves none.

---

## 💡 Memory Trick

```text
Pending             →  never got a node       →  describe pod (Events)
ContainerCreating   →  got a node, stuck      →  describe pod (Events)
ImagePullBackOff    →  can't fetch the image  →  describe pod (Events)
CrashLoopBackOff    →  runs and dies          →  logs --previous ⭐
Running 0/1         →  alive, not ready       →  describe pod (readiness)
OOMKilled           →  used too much memory   →  describe pod (Last State)
Evicted             →  node ran out           →  describe node (Conditions)
```

> **Above `Running`: use `describe`. At `Running`: use `logs`.**

---

## 🔗 Related

[12 · Debugging](../cheatsheets/12-debugging.md) · [Troubleshooting Flow](troubleshooting-flow.md) · [Troubleshooting Mind Map](../mindmaps/troubleshooting-mindmap.md) · [03 · Pods](../cheatsheets/03-pods.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Top 50 Commands](top-50-kubectl-commands.md) | [README](../README.md) | [Troubleshooting Flow →](troubleshooting-flow.md) |
