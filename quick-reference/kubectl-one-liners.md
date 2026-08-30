# 🧰 kubectl One-Liners

**Sharp commands for filtering, extracting, and auditing. Copy, replace the placeholders, run.**

> 🔴 Most of these are Advanced — not because they're long, but because jsonpath and `jq` reward understanding what you're asking for.

---

## 🔍 Finding Things

```bash
# Everything unhealthy, cluster-wide
kubectl get pods -A -o wide | grep -Ev 'Running|Completed'

# Pods sorted by restart count — your flakiest workloads
kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount | tail -20

# Pods sorted by age, newest last
kubectl get pods -A --sort-by=.metadata.creationTimestamp

# All Pods on one node
kubectl get pods -A -o wide --field-selector spec.nodeName=<node-name>

# Every Pod not in Running phase
kubectl get pods -A --field-selector status.phase!=Running

# Find a resource when you don't know the namespace
kubectl get <resource> -A | grep <name>

# Everything with a given label, across resource types
kubectl get all -A -l app=<label-value>
```

---

## 📦 Images & Versions

```bash
# Every unique image running in the cluster
kubectl get pods -A -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u

# Image per Deployment
kubectl get deploy -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[*].image'

# Anything still using the :latest tag
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}' \
  | grep ':latest'

# Kubelet version per node — spot version skew
kubectl get nodes -o custom-columns='NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion'
```

---

## 📊 Resources & Capacity

```bash
# Top memory consumers
kubectl top pods -A --sort-by=memory | head -20

# Top CPU consumers
kubectl top pods -A --sort-by=cpu | head -20

# Requests and limits for every Pod in a namespace
kubectl get pods -o custom-columns=\
'NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,MEM_LIM:.spec.containers[*].resources.limits.memory'

# Every Pod with NO resource requests (BestEffort — evicted first)
kubectl get pods -A -o json | jq -r '
  .items[] | select(.spec.containers[].resources.requests == null) |
  "\(.metadata.namespace)/\(.metadata.name)"'

# QoS class per Pod
kubectl get pods -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,QOS:.status.qosClass'

# Committed requests per node (what the scheduler sees)
kubectl describe nodes | grep -A4 "Allocated resources"

# Max pods per node — often the real limit on EKS
kubectl get nodes -o custom-columns='NAME:.metadata.name,MAX_PODS:.status.allocatable.pods'
```

---

## 🌐 Networking

```bash
# Every Service and its selector
kubectl get svc -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,SELECTOR:.spec.selector'

# Services with NO endpoints — broken selectors or unready Pods
kubectl get endpoints -A -o json | jq -r '
  .items[] | select(.subsets == null or (.subsets | length) == 0) |
  "\(.metadata.namespace)/\(.metadata.name)"'

# Every LoadBalancer Service — each one is a cloud bill
kubectl get svc -A --field-selector spec.type=LoadBalancer

# Every Ingress host
kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\t"}{.spec.rules[*].host}{"\n"}{end}'

# Pod IPs with their names
kubectl get pods -o custom-columns='NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName'

# Namespaces that have NetworkPolicies
kubectl get netpol -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name'
```

---

## 💾 Storage

```bash
# PVCs with their bound volumes and classes
kubectl get pvc -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,SIZE:.spec.resources.requests.storage,CLASS:.spec.storageClassName'

# ⚠️ PVs that will DESTROY data on PVC deletion
kubectl get pv -o json | jq -r '
  .items[] | select(.spec.persistentVolumeReclaimPolicy == "Delete") |
  "\(.metadata.name) → \(.spec.claimRef.namespace // "unbound")/\(.spec.claimRef.name // "-")"'

# Unbound PVCs
kubectl get pvc -A --field-selector status.phase=Pending

# Released PVs — data retained, storage still billed
kubectl get pv --field-selector status.phase=Released

# Which Pods mount which PVCs
kubectl get pods -o json | jq -r '
  .items[] | select(.spec.volumes[]?.persistentVolumeClaim) |
  "\(.metadata.name): \(.spec.volumes[] | select(.persistentVolumeClaim) | .persistentVolumeClaim.claimName)"'
```

---

## 🔐 Security & RBAC

```bash
# Who has cluster-admin
kubectl get clusterrolebindings -o json | jq -r '
  .items[] | select(.roleRef.name == "cluster-admin") |
  "\(.metadata.name): \(.subjects // [] | map(.kind + "/" + .name) | join(", "))"'

# Every binding for one subject
kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '
  .items[] | select(.subjects[]?.name == "<subject-name>") |
  "\(.kind)/\(.metadata.name) in \(.metadata.namespace // "cluster") → \(.roleRef.kind)/\(.roleRef.name)"'

# Custom (non-system) ClusterRoles
kubectl get clusterroles | grep -v '^system:'

# ServiceAccount used by each Pod
kubectl get pods -A -o custom-columns='NS:.metadata.namespace,POD:.metadata.name,SA:.spec.serviceAccountName'

# Pods running as root
kubectl get pods -A -o json | jq -r '
  .items[] | select(.spec.securityContext.runAsNonRoot != true) |
  "\(.metadata.namespace)/\(.metadata.name)"'

# Privileged containers
kubectl get pods -A -o json | jq -r '
  .items[] | select(.spec.containers[].securityContext.privileged == true) |
  "\(.metadata.namespace)/\(.metadata.name)"'
```

---

## 🧹 Cleanup

> ⚠️ Every command in this section deletes things. Confirm your context first: `kubectl config current-context`

```bash
# Delete evicted / failed Pods
kubectl delete pods -A --field-selector status.phase=Failed

# Delete completed Jobs, keeping failures for investigation
kubectl delete jobs --field-selector status.successful=1 -n <namespace>

# Delete Pods by label
kubectl delete pods -l app=<label-value>

# Find cordoned nodes you forgot to uncordon
kubectl get nodes | grep SchedulingDisabled

# Find suspended CronJobs — silently not running
kubectl get cronjobs -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,SUSPEND:.spec.suspend,LAST:.status.lastScheduleTime' | grep true
```

---

## 📜 Events & Logs

```bash
# Recent events, cluster-wide
kubectl get events -A --sort-by=.lastTimestamp | tail -30

# Warnings only
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp | tail -20

# Events for one object
kubectl get events --field-selector involvedObject.name=<pod-name> --sort-by=.lastTimestamp

# Logs from every Pod matching a label
kubectl logs -l app=<label-value> --all-containers=true --max-log-requests=10 --tail=50

# Logs from the last 15 minutes with timestamps
kubectl logs <pod-name> --since=15m --timestamps

# Grep across all replicas
kubectl logs -l app=<label-value> --tail=-1 | grep -i error
```

---

## ⚡ Workflow

```bash
# Diff every manifest in a directory (exit 1 = drift)
kubectl diff -f ./manifests/ && echo "no drift" || echo "⚠️ drift detected"

# Apply, wait, verify — the deployment pipeline
kubectl apply -f ./manifests/ && \
kubectl rollout status deployment/<deployment-name> --timeout=300s

# Restart every Deployment in a namespace
kubectl get deploy -n <namespace> -o name | xargs -n1 kubectl rollout restart -n <namespace>

# Describe everything matching a label
kubectl get pods -l app=<label-value> -o name | xargs -n1 kubectl describe

# Watch a rollout with Pod detail
kubectl get pods -l app=<label-value> -o wide -w

# Genuinely enumerate a namespace (get all does NOT do this)
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```

---

## 🧾 JSONPath Cookbook

```bash
# One field
kubectl get pod <pod-name> -o jsonpath='{.status.podIP}'

# One field from every item
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# One per line
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# Two fields, tab separated
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'

# Filter by a field value
kubectl get pods -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}'

# Container names in a Pod
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'

# Decode every key of a Secret (⚠️ prints credentials)
kubectl get secret <secret-name> -o go-template='{{range $k,$v := .data}}{{$k}}: {{$v|base64decode}}{{"\n"}}{{end}}'
```

> 💡 `{range}...{end}` is what makes jsonpath readable. Without it everything lands on one space-separated line. For tabular output, `-o custom-columns` is usually clearer than jsonpath.

---

## 🔗 Related

[15 · Productivity](../cheatsheets/15-kubectl-productivity.md) · [Command Patterns](command-patterns.md) · [Top 50](top-50-kubectl-commands.md) · [Scenarios](scenarios.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← Scenarios](scenarios.md) | [README](../README.md) | [Interview Guide →](interview-survival-guide.md) |
