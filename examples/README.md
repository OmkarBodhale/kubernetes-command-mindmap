# 📁 Examples

**Minimal, working manifests — each one paired with the command that generates it.**

> 💡 **The point of this folder is not the YAML.** It's the `--dry-run=client -o yaml` command above each file. Learn to generate manifests from your own cluster and you never copy an outdated API version from a blog post again.

---

## The Files

| File | Generate it with | Notes |
| --- | --- | --- |
| [`pod.yaml`](pod.yaml) | `kubectl run web --image=nginx:1.27 --port=80 --dry-run=client -o yaml` | ⚠️ Testing only — nothing manages a bare Pod |
| [`deployment.yaml`](deployment.yaml) | `kubectl create deployment web --image=nginx:1.27 --replicas=3 --port=80 --dry-run=client -o yaml` | The one you'll actually use |
| [`service.yaml`](service.yaml) | `kubectl expose deployment web --port=80 --target-port=80 --dry-run=client -o yaml` | Selector must match Pod labels |
| [`configmap.yaml`](configmap.yaml) | `kubectl create configmap app-config --from-literal=LOG_LEVEL=info --dry-run=client -o yaml` | Changes need a `rollout restart` |
| [`secret.yaml`](secret.yaml) | `kubectl create secret generic db-secret --from-literal=username=admin --dry-run=client -o yaml` | ⚠️ Never commit a real one |
| [`pvc.yaml`](pvc.yaml) | *(no imperative command — PVCs are declarative only)* | Check the reclaim policy before deleting |
| [`ingress.yaml`](ingress.yaml) | `kubectl create ingress web --class=nginx --rule="shop.example.com/*=web:80" --dry-run=client -o yaml` | Needs a controller installed |
| [`job.yaml`](job.yaml) | `kubectl create job migrate --image=busybox:1.36 --dry-run=client -o yaml -- /bin/sh -c 'echo hi'` | Runs to completion |
| [`cronjob.yaml`](cronjob.yaml) | `kubectl create cronjob backup --image=busybox:1.36 --schedule="0 2 * * *" --dry-run=client -o yaml -- /bin/sh -c 'echo hi'` | ⚠️ UTC unless `timeZone` is set |

---

## Apply Order

Dependencies matter. Config before workload, workload before routing:

```text
1. Namespace                    kubectl create namespace demo
2. ConfigMap + Secret           configmap.yaml · secret.yaml
3. PVC                          pvc.yaml
4. Deployment                   deployment.yaml
5. Service                      service.yaml
6. Ingress                      ingress.yaml
7. Job / CronJob                job.yaml · cronjob.yaml
```

Applying out of order gives you a `CreateContainerConfigError` Pod that fixes itself once the ConfigMap exists — but it's cleaner to just apply in order.

---

## Try It End to End

```bash
kubectl create namespace demo
kubectl config set-context --current --namespace=demo

kubectl apply -f configmap.yaml -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

kubectl rollout status deployment/web
kubectl get pods -o wide
kubectl get endpoints web              # ← should list Pod IPs, not <none>

kubectl port-forward svc/web 8080:80
# open http://localhost:8080
```

**Clean up:**

```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace demo
```

> ⚠️ Deleting a namespace deletes **everything inside it**, including PVCs — and with a `Delete` reclaim policy that destroys the underlying disk.

---

## Deliberately Break Things

The fastest way to learn debugging is to cause failures on purpose. Each of these produces a distinct, recognisable state:

```bash
# ImagePullBackOff
kubectl set image deployment/web web=nginx:does-not-exist

# CrashLoopBackOff
kubectl set image deployment/web web=busybox:1.36
kubectl patch deployment web -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"web","command":["/bin/false"]}]}}}}'

# Service with no endpoints
kubectl patch svc web -p '{"spec":{"selector":{"app":"wrong-label"}}}'

# OOMKilled
kubectl set resources deployment/web -c=web --limits=memory=4Mi

# Pending (unschedulable)
kubectl set resources deployment/web -c=web --requests=cpu=1000
```

Diagnose each one using [Failure States](../quick-reference/failure-states.md), then recover:

```bash
kubectl rollout undo deployment/web
```

---

## Conventions in These Files

Every file follows the repository's rules:

- **Pinned image tags** — never `:latest`, which Kubernetes can't tell has changed
- **Resource requests and limits set** — a memory limit always; a CPU limit only when justified
- **Probes configured** — readiness gates traffic, liveness restarts
- **⚠️ comments on the traps** — the immutable selector, `pathType: Prefix`, `ReadWriteOnce` meaning one *node*, base64 not being encryption
- **Placeholders as `<angle-brackets>`** in the surrounding commands

---

## 🔗 Related

[15 · Productivity — generating YAML](../cheatsheets/15-kubectl-productivity.md#-generate-yaml-without-writing-yaml) · [Command Patterns](../quick-reference/command-patterns.md#-the-generation-pattern) · [Failure States](../quick-reference/failure-states.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← 30-Day Plan](../quick-reference/30-day-command-plan.md) | [README](../README.md) | [README →](../README.md) |
