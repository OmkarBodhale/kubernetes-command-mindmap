# 🎯 "What Command Do I Use?"

**You know what you want. This page gives you the command. 40 real scenarios.**

---

## 🔍 Inspecting

### I want to see what's running

```bash
kubectl get pods
kubectl get pods -A          # every namespace
```

### I want to know where my Pod is running

```bash
kubectl get pod <pod-name> -o wide
```

The `NODE` column. Add `-A` to search across namespaces.

### I want to see all my resources

```bash
kubectl get all
kubectl get all -n <namespace>
```

> ⚠️ **`kubectl get all` does not return everything.** It covers roughly Pods, Services, Deployments, ReplicaSets, StatefulSets, DaemonSets, Jobs, and CronJobs. It **omits** ConfigMaps, Secrets, PVCs, Ingresses, ServiceAccounts, Roles, NetworkPolicies, and every CRD. Never use it to confirm a namespace is empty.
>
> To genuinely enumerate a namespace:
> ```bash
> kubectl api-resources --verbs=list --namespaced -o name \
>   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
> ```

### I want to find a resource but don't know its namespace

```bash
kubectl get <resource> -A | grep <name>
```

### I want to see what changed recently

```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -30
```

### I want to know what this cluster can do

```bash
kubectl api-resources
kubectl get crds
```

### I want to know which cluster I'm on

```bash
kubectl config current-context
```

Run this before anything destructive. Every time.

---

## 🐛 Debugging

### I want to know why my Pod is failing

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

Read `describe` bottom-up — the Events section names the cause.

### I want logs from the container that just crashed

```bash
kubectl logs <pod-name> --previous
```

The current container may have started two seconds ago and logged nothing.

### I want to follow logs live

```bash
kubectl logs -f <pod-name>
kubectl logs -f deployment/<deployment-name>
```

### I want logs from all replicas at once

```bash
kubectl logs -l app=<label-value> --all-containers=true --max-log-requests=10 --tail=50
```

### I want to get inside the container

```bash
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -it <pod-name> -- /bin/bash    # if bash exists
```

### The image has no shell

```bash
kubectl debug -it <pod-name> --image=busybox:1.36 --target=<container-name>
```

An ephemeral container sharing the target's process namespace. Stable since v1.25.

### I want to see everything unhealthy in the cluster

```bash
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'
```

### I want to find my flakiest Pods

```bash
kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount | tail -20
```

### I want to see what the container actually received

```bash
kubectl exec <pod-name> -- env | sort
kubectl exec <pod-name> -- cat /etc/config/<file>
```

What's in the ConfigMap and what's in the container are different questions.

---

## 🚀 Deploying & Changing

### I want to deploy something

```bash
kubectl apply -f <file>.yaml
kubectl apply -f <directory>/
```

### I want to see what a deploy will change first

```bash
kubectl diff -f <file>.yaml
```

Thirty seconds that has prevented a lot of incidents.

### I want to restart an application

```bash
kubectl rollout restart deployment/<deployment-name>
```

> 💡 Don't delete Pods to restart an app — that kills them all at once. `rollout restart` is gradual and respects readiness probes.

### I want to change the number of replicas

```bash
kubectl scale deployment/<deployment-name> --replicas=<n>
```

Check for an HPA first (`kubectl get hpa`) — it will revert manual scaling.

### I want to deploy a new image version

```bash
kubectl set image deployment/<deployment-name> <container-name>=<image>:<tag>
kubectl rollout status deployment/<deployment-name>
```

The left side is the **container name**, not the image name.

### I want to undo a bad deploy

```bash
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>
```

> ⚠️ Reverts the Pod template only — not database migrations or ConfigMaps.

### I want to know if my deploy finished

```bash
kubectl rollout status deployment/<deployment-name> --timeout=5m
```

Exits non-zero on failure — the right command for CI.

### I want to take an app offline without deleting it

```bash
kubectl scale deployment/<deployment-name> --replicas=0
```

> ⚠️ This is an outage. Deliberate, but an outage.

### I want to pick up a ConfigMap change

```bash
kubectl rollout restart deployment/<deployment-name>
```

Env vars are frozen at container start; they never reload on their own.

---

## 🌐 Networking

### I want to test an application locally

```bash
kubectl port-forward svc/<service-name> 8080:80
```

Then open `http://localhost:8080`. `8080` is your machine, `80` is the Service port.

### I want to know why my Service returns nothing

```bash
kubectl get endpoints <service-name>
```

`<none>` → labels or readiness. Populated → ports or policy.

### I want to check DNS from inside the cluster

```bash
kubectl run tmp --rm -it --image=busybox:1.36 --restart=Never -- /bin/sh
# then: nslookup <service-name>.<namespace>.svc.cluster.local
```

### I want a full network toolbox

```bash
kubectl run netshoot --rm -it --image=nicolaka/netshoot --restart=Never -- /bin/bash
```

`dig`, `curl`, `nslookup`, `tcpdump`, `netstat`, `nc`.

### I want to expose a Deployment

```bash
kubectl expose deployment <deployment-name> --port=80 --target-port=8080
```

`--port` is what callers use; `--target-port` is where the container listens.

### I want to test an Ingress before DNS exists

```bash
kubectl get ingress
curl -H "Host: <hostname>" http://<ingress-address>/
```

---

## ⚙️ Configuration

### I want to read a Secret's value

```bash
kubectl get secret <secret-name> -o jsonpath='{.data.<key>}' | base64 -d; echo
```

> ⚠️ This prints a credential into your terminal — scrollback, shell history, and any screen recording. Never during a screen share.

### I want to update a ConfigMap from the command line

```bash
kubectl create configmap <name> --from-literal=<key>=<value> \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/<deployment-name>
```

### I want to fix `ImagePullBackOff` on a private image

```bash
kubectl create secret docker-registry <name> \
  --docker-server=<registry> --docker-username=<user> --docker-password=<pass>
```

Then reference it in the Pod spec's `imagePullSecrets`.

---

## 💾 Storage

### I want to know why my PVC is Pending

```bash
kubectl describe pvc <pvc-name>
kubectl get sc                      # is one marked (default)?
```

> `waiting for first consumer` is **normal** — it binds once a Pod is scheduled.

### I want to make a volume bigger

```bash
kubectl get sc <storageclass-name> -o jsonpath='{.allowVolumeExpansion}'
kubectl patch pvc <pvc-name> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

> ⚠️ Volumes can only grow. There is no way to shrink one.

### I want to check whether a volume is full

```bash
kubectl exec <pod-name> -- df -h
```

### I want to know if deleting a PVC will destroy the data

```bash
kubectl get pvc <pvc-name> -o jsonpath='{.spec.volumeName}'
kubectl get pv <pv-name> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
```

`Delete` — the cloud default — destroys the real disk. `Retain` keeps it.

---

## 📊 Resources

### I want to know what's using CPU and memory

```bash
kubectl top pods -A --sort-by=memory | head -20
kubectl top nodes
```

### I want to know why a Pod won't schedule when the node looks idle

```bash
kubectl describe node <node-name> | grep -A10 "Allocated resources"
```

Scheduling uses **requests**, not usage. A node at 15% CPU can be full.

### I want to find Pods with no resource limits

```bash
kubectl get pods -A -o json | jq -r '
  .items[] | select(.spec.containers[].resources.requests == null) |
  "\(.metadata.namespace)/\(.metadata.name)"'
```

These are `BestEffort` — evicted first under pressure.

---

## ⚙️ Cluster Operations

### I want to safely take a node out of service

```bash
kubectl get pods -A -o wide --field-selector spec.nodeName=<node-name>
kubectl get pdb -A
kubectl drain <node-name> --ignore-daemonsets --dry-run=client
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --timeout=300s
# ...maintenance...
kubectl uncordon <node-name>
```

### I want to stop new Pods landing on a sick node

```bash
kubectl cordon <node-name>
```

Safe, reversible, doesn't disturb what's running.

### I want to find cordoned nodes I forgot about

```bash
kubectl get nodes | grep SchedulingDisabled
```

### I want to switch clusters

```bash
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config current-context
```

### I want to stop typing `-n` everywhere

```bash
kubectl config set-context --current --namespace=<namespace>
```

---

## 🔐 Permissions

### I want to know if I can do something

```bash
kubectl auth can-i <verb> <resource>
kubectl auth can-i --list
```

### I want to know why my app gets 403

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>
```

If the first returns `default`, the Pod spec is missing `serviceAccountName`.

### I want to know who has cluster-admin

```bash
kubectl get clusterrolebindings -o json | jq -r '
  .items[] | select(.roleRef.name == "cluster-admin") |
  "\(.metadata.name): \(.subjects // [] | map(.kind + "/" + .name) | join(", "))"'
```

---

## ⏱️ Jobs

### I want to run a CronJob right now

```bash
kubectl create job <job-name> --from=cronjob/<cronjob-name>
```

Uses exactly the template the schedule would have used.

### I want to know why my scheduled job didn't run

```bash
kubectl get cronjob <cronjob-name>       # is SUSPEND=True?
kubectl get jobs --sort-by=.metadata.creationTimestamp
kubectl logs -l job-name=<job-name>
```

> CronJobs run in **UTC** unless `spec.timeZone` is set.

### I want to pause a CronJob

```bash
kubectl patch cronjob <cronjob-name> -p '{"spec":{"suspend":true}}'
```

---

## ⚡ Learning & Productivity

### I want to write YAML without writing YAML

```bash
kubectl create deployment <name> --image=<image> --dry-run=client -o yaml > deployment.yaml
```

### I want to know what fields a resource has

```bash
kubectl explain <resource>.spec
kubectl explain <resource>.spec --recursive
```

Works for CRDs too — it's your cluster's own API documentation.

### I want to copy a file out of a Pod

```bash
kubectl cp <namespace>/<pod-name>:/path/to/file ./local-file
```

### I want to know every image running in the cluster

```bash
kubectl get pods -A -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u
```

---

## 🔗 Related

[Top 50 Commands](top-50-kubectl-commands.md) · [Command Patterns](command-patterns.md) · [One-Liners](kubectl-one-liners.md) · [Troubleshooting Flow](troubleshooting-flow.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Troubleshooting Flow](troubleshooting-flow.md) | [README](../README.md) | [One-Liners →](kubectl-one-liners.md) |
