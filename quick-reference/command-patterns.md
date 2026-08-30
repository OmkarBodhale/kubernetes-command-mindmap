# 🔑 Command Patterns — The Cheat Code

**The most important page in this repository. kubectl mastery is not memorizing commands — it is learning about a dozen patterns and filling in the blanks.**

---

## 🧠 The One Pattern

```bash
kubectl <verb> <resource> <name> <flags>
```

That's it. Nearly every kubectl command is that shape.

**Instead of memorizing this:**

```text
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets
kubectl get nodes
kubectl get ingress
kubectl get pvc
```

**Remember this:**

```bash
kubectl get <resource>
```

Eight things to remember becomes one. And it keeps working for resources you've never seen — including CRDs installed by operators:

```bash
kubectl get certificates        # cert-manager
kubectl get applications        # Argo CD
kubectl get virtualservices     # Istio
```

You didn't learn those. You derived them.

```bash
kubectl api-resources
```

That prints every resource your cluster supports. **The pattern plus this command replaces every list of commands you'll ever be handed.**

---

## 📋 The Twelve Patterns

Each one takes any resource type.

### 1. `get` — list things

```bash
kubectl get <resource>
kubectl get <resource> <name>
kubectl get <resource> -n <namespace>
kubectl get <resource> -A
kubectl get <resource> -o wide
kubectl get <resource> -l <key>=<value>
kubectl get <resource> -w
```

### 2. `describe` — detail plus events

```bash
kubectl describe <resource> <name>
kubectl describe <resource> -l <key>=<value>
```

> 💡 Always read `describe` **bottom-up**. The Events section is the answer.

### 3. `create` — make it now (imperative)

```bash
kubectl create <resource> <name> [options]
kubectl create <resource> <name> [options] --dry-run=client -o yaml
```

### 4. `apply` — make the cluster match a file (declarative)

```bash
kubectl apply -f <file>.yaml
kubectl apply -f <directory>/
kubectl apply -k <kustomize-dir>/
```

### 5. `delete` — remove it

```bash
kubectl delete <resource> <name>
kubectl delete -f <file>.yaml
kubectl delete <resource> -l <key>=<value>
```

> ⚠️ No undo, no confirmation. Check `kubectl config current-context` first.

### 6. `edit` — change the live object

```bash
kubectl edit <resource> <name>
```

### 7. `logs` — read output

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
kubectl logs -f <pod-name>
kubectl logs -l <key>=<value>
kubectl logs deployment/<name>
```

### 8. `exec` — run something inside

```bash
kubectl exec <pod-name> -- <command>
kubectl exec -it <pod-name> -- /bin/sh
kubectl exec -it <pod-name> -c <container-name> -- /bin/sh
```

### 9. `scale` — change replica count

```bash
kubectl scale <resource>/<name> --replicas=<n>
```

Works on Deployments, ReplicaSets, StatefulSets, and ReplicationControllers.

### 10. `rollout` — manage a deploy

```bash
kubectl rollout status  <resource>/<name>
kubectl rollout history <resource>/<name>
kubectl rollout undo    <resource>/<name>
kubectl rollout restart <resource>/<name>
kubectl rollout pause   <resource>/<name>
kubectl rollout resume  <resource>/<name>
```

Works on Deployments, StatefulSets, and DaemonSets.

### 11. `label` / `annotate` — attach metadata

```bash
kubectl label    <resource> <name> <key>=<value>
kubectl label    <resource> <name> <key>=<value> --overwrite
kubectl label    <resource> <name> <key>-
kubectl annotate <resource> <name> <key>=<value>
```

Trailing `-` removes. Works on every resource.

### 12. `explain` — the docs

```bash
kubectl explain <resource>
kubectl explain <resource>.<field>
kubectl explain <resource>.<field> --recursive
```

---

## 🎛️ The Flags That Work Everywhere

Learn these once; they apply across almost every command.

| Flag | Does |
| --- | --- |
| `-n <namespace>` | One namespace |
| `-A` / `--all-namespaces` | Every namespace |
| `-o wide` | More columns |
| `-o yaml` / `-o json` | The raw object |
| `-o name` | Just `kind/name`, for piping |
| `-o jsonpath='...'` | Extract specific fields |
| `-o custom-columns='...'` | Choose your columns |
| `-l <key>=<value>` | Filter by label |
| `--field-selector <field>=<value>` | Filter by field |
| `-w` / `--watch` | Stream changes |
| `--sort-by=<jsonpath>` | Sort output |
| `--dry-run=client -o yaml` | Generate, don't create |
| `-f <file>` | Read from a file |
| `--show-labels` | Add a labels column |

**Combine freely:**

```bash
kubectl get pods -A -o wide -l app=web --sort-by=.metadata.creationTimestamp
```

You never learned that command. You composed it.

---

## 🔤 The Short Names

```bash
kubectl get po      # pods
kubectl get deploy  # deployments
kubectl get svc     # services
kubectl get ns      # namespaces
kubectl get cm      # configmaps
kubectl get pvc     # persistentvolumeclaims
kubectl get sa      # serviceaccounts
kubectl get sts     # statefulsets
kubectl get ds      # daemonsets
kubectl get rs      # replicasets
kubectl get ing     # ingresses
kubectl get sc      # storageclasses
kubectl get cj      # cronjobs
kubectl get hpa     # horizontalpodautoscalers
kubectl get netpol  # networkpolicies
kubectl get crd     # customresourcedefinitions
```

Full list for your cluster: `kubectl api-resources`

---

## 🏗️ The Generation Pattern

Any `create` command becomes a YAML generator:

```bash
kubectl create <anything> [options] --dry-run=client -o yaml
```

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl create deployment web --image=nginx --dry-run=client -o yaml
kubectl expose deployment web --port=80 --dry-run=client -o yaml
kubectl create configmap app --from-literal=K=V --dry-run=client -o yaml
kubectl create secret generic db --from-literal=pw=x --dry-run=client -o yaml
kubectl create job migrate --image=app --dry-run=client -o yaml
kubectl create cronjob backup --image=app --schedule="0 2 * * *" --dry-run=client -o yaml
kubectl create ingress web --class=nginx --rule="h/p=svc:80" --dry-run=client -o yaml
kubectl create namespace prod --dry-run=client -o yaml
kubectl create role reader --verb=get --resource=pods --dry-run=client -o yaml
```

> 💡 **Stop writing YAML from memory.** Generate a correct skeleton from your own cluster, then edit it.

---

## 🧩 Command Memory Chains

Sequences, not single commands. This is how experienced engineers actually work.

### Pod troubleshooting

```text
GET → DESCRIBE → LOGS → EXEC
```
> Find it → Inspect it → Read what happened → Enter it.

### Deployment troubleshooting

```text
GET → DESCRIBE → ROLLOUT STATUS → PODS → LOGS
```
> Is it there? What is it? Did it finish? Are the Pods OK? What did they say?

### Network troubleshooting

```text
POD → SERVICE → ENDPOINTS → INGRESS → DNS
```
> Is it running? Is it fronted? Is it wired? Is it routed? Is it named?

### Storage troubleshooting

```text
POD → PVC → PV → STORAGECLASS → CSI
```
> Pod wants it, Claim asks for it, Volume is it, Class makes it, Driver attaches it.

### RBAC troubleshooting

```text
WHO → CAN-I → ROLE → BINDING
```
> Which identity? Is it allowed? What grants it? Is it connected?

### Config troubleshooting

```text
EXEC env → CONFIGMAP → SECRET → ROLLOUT RESTART
```
> What did the container get? What should it have got? Restart to pick it up.

### Node troubleshooting

```text
GET NODES → DESCRIBE NODE → CONDITIONS → TOP
```
> Which node? What state? Why? How loaded?

### Node maintenance

```text
CORDON → DRAIN → PATCH → UNCORDON → VERIFY
```
> Closed sign, empty the building, do the work, reopen, check.

### Safe deployment

```text
DIFF → APPLY → ROLLOUT STATUS → LOGS
```
> See the change, make the change, watch it land, confirm it works.

### Helm deployment

```text
SHOW VALUES → TEMPLATE → UPGRADE --INSTALL → LIST → STATUS
```
> Read the options, render it, deploy it, confirm it, inspect it.

### Cluster orientation (a cluster you've never seen)

```text
CURRENT-CONTEXT → GET NODES → GET NS → GET PODS -A → API-RESOURCES
```
> Where am I? Is it healthy? What lives here? What's running? What's installed?

---

## 🎯 The Resource-Type Mental Map

Group resources by what they do, not alphabetically:

```text
RUN THINGS       pods · deployments · replicasets · statefulsets · daemonsets · jobs · cronjobs
CONNECT THINGS   services · endpoints · ingresses · ingressclasses · networkpolicies
CONFIGURE THINGS configmaps · secrets
STORE THINGS     persistentvolumeclaims · persistentvolumes · storageclasses
SECURE THINGS    serviceaccounts · roles · rolebindings · clusterroles · clusterrolebindings
ORGANIZE THINGS  namespaces · resourcequotas · limitranges
THE MACHINES     nodes · events
```

---

## 💡 The Compression

Everything above, in four lines:

```text
kubectl <verb> <resource> <name> <flags>

Don't know the resource?  →  kubectl api-resources
Don't know the field?     →  kubectl explain <resource>.<field>
Don't want to write YAML? →  --dry-run=client -o yaml
```

> **You do not need to memorize kubectl. You need to memorize its grammar, and let the cluster tell you the vocabulary.**

---

## 🔗 Related

[README — the grammar](../README.md) · [Master Mind Map](../mindmaps/kubectl-master-mindmap.md) · [Top 50 Commands](top-50-kubectl-commands.md) · [15 · Productivity](../cheatsheets/15-kubectl-productivity.md) · [One-Liners](kubectl-one-liners.md)

---

<!-- NAV-FOOTER -->
### 🧭 Navigation

| Previous | Up | Next |
| --- | --- | --- |
| [← 17 · Helm](../cheatsheets/17-helm-commands.md) | [README](../README.md) | [Top 50 Commands →](top-50-kubectl-commands.md) |
