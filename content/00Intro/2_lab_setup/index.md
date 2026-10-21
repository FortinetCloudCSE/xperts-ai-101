---
title: "Kubernetes / Helm Setup"
linkTitle: "Kubernetes / Helm"
weight: 3
---

## Prerequisites

kubectl, Helm and jq are already installed on the bastion (the Linux VM provided for your session). The table below is for reference — you don't need to install anything.

| Requirement | Version | Check | Purpose
| ------------- | --------- | ------- | -----
| kubectl | 1.28+ | `kubectl version --client` | Managing K8S clusters |
| Helm | 3.14+ | `helm version` | Package manager automating the creation, packaging, configuration, and deployment of application |
| jq | 1.6+ | `jq --version` | lightweight and flexible command-line JSON processor used to slice, filter, map, and transform the highly detailed JSON data returned by the Kubernetes API |
| Running cluster | — | `kubectl cluster-info` | Get info on an existing cluster|
| Default StorageClass | — | `kubectl get storageclass` | Get info on cluster storage |

## 1. Verify Kubernetes access {{% badge style="red" %}} REQUIRED {{% /badge %}}

Confirm kubectl is pointed at your cluster:

```bash {run="bastion"}
kubectl config current-context
```

List the cluster nodes:

```bash {run="bastion"}
kubectl get nodes
```

```output {collapse="true" hl_lines="4 6"}
aiuser@vm-linux-aiuser49:~$ az aks list --resource-group ${RESOURCE_GROUP_NAME} --output table
Name          Location    ResourceGroup             KubernetesVersion    CurrentKubernetesVersion    ProvisioningState    Fqdn
------------  ----------  ------------------------  -------------------  --------------------------  -------------------  ----------------------------------------------------------------
aks-aiuser49  eastus      rg-xperts-ai101-aiuser49  1.35                 1.35.8                      Succeeded            aks-aiuser-rg-xperts-ai101--02b500-bc473s4a.hcp.eastus.azmk8s.io
aiuser@vm-linux-aiuser49:~$ kubectl config current-context
aks-aiuser49
aiuser@vm-linux-aiuser49:~$ kubectl get nodes
NAME                             STATUS   ROLES    AGE     VERSION
aks-worker-29780268-vmss000000   Ready    <none>   6m33s   v1.35.8
```

If `kubectl get nodes` works, you are connected to the cluster and can continue to the next step.  You should see 'kubectl' pointing to the cluster you created on the initial AKS Cluster creation step!

## 2. Install the chart for Lab 1 {{% badge style="red" %}} REQUIRED {{% /badge %}}

The workshop repo is already cloned on the bastion (the Linux VM provided for your session) at `~/xperts-ai-101`. It supplies Helm with the settings for each lab environment, plus the code that runs the AI components of the labs.

Pre-built multi-arch images (amd64 + arm64) are published to GitHub Container Registry (GHCR) and pulled automatically by the cluster — no manual image pull required.

Install the Lab 1 chart, which deploys Ollama only. Ollama is the program that downloads and runs the AI model (here `qwen2.5:3b`, a small 3-billion-parameter language model) inside your cluster. Running a model to get a reply is called **inference**; Helm is the Kubernetes package manager that installs the chart for you:

```bash {run="bastion"}
cd ~/xperts-ai-101/lab-app/helm
helm upgrade --install ai101 ./ai101 -f ai101/values-lab1.yaml
```

The output is similar to:

```output {collapse="true"}
Release "ai101" does not exist. Installing it now.
NAME: ai101
LAST DEPLOYED: Tue Jul 14 18:35:02 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
```

Wait for the Ollama pod to start, then watch it move to `Running` (this can take 60–90 seconds while the image pulls). This command watches continuously — stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd> once you see `Running`:

```bash {run="bastion"}
kubectl get pods -w
```

The output is similar to:

```output {collapse="true"}
NAME                           READY   STATUS    RESTARTS   AGE
ai101-ollama-8699cc758-sqrgt   1/1     Running   0          12m
```

Once the `ai101-ollama-*` pod shows `Running`, follow its logs to confirm the model download completed. This command streams continuously — stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd> when you're done:

```bash {run="bastion"}
kubectl logs -l app.kubernetes.io/component=ollama -f
```

The output is similar to:

```output {collapse="true"}
kubernetes.io/component=ollama -f
pulling 161ddde4c9cd... 100% ▕████████████████▏  487 B                     
    
verifying sha256 digest 
writing manifest 
success 
Pull complete.
Model ready: qwen2.5:3b
[GIN] 2026/09/29 - 20:47:24 | 200 |      27.337µs |       127.0.0.1 | HEAD 
    "/"
[GIN] 2026/09/29 - 20:47:24 | 200 |     337.089µs |       127.0.0.1 | GET  
    "/api/tags"
[GIN] 2026/09/29 - 20:47:34 | 200 |      28.101µs |       127.0.0.1 | HEAD 
    "/"
[GIN] 2026/09/29 - 20:47:34 | 200 |     314.953µs |       127.0.0.1 | GET  
    "/api/tags"
[GIN] 2026/09/29 - 20:47:44 | 200 |      24.998µs |       127.0.0.1 | HEAD 
    "/"
[GIN] 2026/09/29 - 20:47:44 | 200 |     307.093µs |       127.0.0.1 | GET  
    "/api/tags"
[GIN] 2026/09/29 - 20:47:54 | 200 |      28.458µs |       127.0.0.1 | HEAD 
    "/"
```

## 3. Verify {{% badge style="red" %}} REQUIRED {{% /badge %}}

Ollama listens on a port inside the cluster that the bastion can't reach directly, so a **port-forward** (a temporary tunnel from the bastion into the cluster) is needed. The command below backgrounds the tunnel with `&` so it keeps running while you do other things:

```bash {run="bastion"}
kubectl port-forward svc/ai101-ollama 11434:11434 > /tmp/ai101-ollama-port-forward.log 2>&1 < /dev/null &
```

{{% notice style="warning" title="If you lose your Linux session connection" %}}
If your connection to the Linux session (the bastion) drops, the background port-forward dies with it. Re-run the same `kubectl port-forward` command above to restart it before continuing.
{{% /notice %}}

Send a test prompt to the Ollama OpenAI-compatible API endpoint (the same HTTP request format OpenAI's API uses, so most AI tools can talk to it). A **prompt** is the text you send to the model. This one is just a user message with no system prompt:

```bash {run="bastion"}
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:3b","messages":[{"role":"user","content":"ping"}]}' \
  | jq -r '.choices[0].message.content'
```

{{% badge style="green" %}} Note {{% /badge %}} If the command returns a text response, Ollama is running and the model is able to perform inference. The output is similar to:

```output {collapse="true"}
Pong! Your ping request was successfully answered. How can I assist you further?
```

**What you just saw:** `kubectl port-forward` created a temporary connection from `localhost:11434` to the Ollama service inside the cluster. The `curl` command sent a small test prompt to that local endpoint, Kubernetes forwarded it to Ollama, Ollama ran the model, and the reply came back to the bastion. Every lab builds on this path, so if later commands fail with "connection refused", the port-forward is the first thing to check. The model's wording will differ on each run.

## 4. Reference — upgrade per lab {{% badge style="aqua" %}} Informational {{% /badge %}}

Each lab tells you which of these to run to set up for its exercises. This is for reference only — run only the command for the lab you're on:

```bash
cd ~/xperts-ai-101/lab-app/helm

# Lab 1 — Ollama only (already done above)
helm upgrade --install ai101 ./ai101 -f ai101/values-lab1.yaml

# Lab 2 — Agent (hardcoded tools) + UI
helm upgrade --install ai101 ./ai101 -f ai101/values-lab2.yaml

# Lab 3 — Agent (MCP mode) + MCP server + UI
helm upgrade --install ai101 ./ai101 -f ai101/values-lab3.yaml

# Lab 4 — Same as lab3 (security demo steps use env overrides)
helm upgrade --install ai101 ./ai101 -f ai101/values-lab4.yaml
```

{{% notice style="tip" title="Keep it running" %}}
Leave the release running as you work through the labs. Each lab section tells you which values file to upgrade to. Only uninstall when you are completely done.
{{% /notice %}}

---

## 5. FortiAIGate routing {{% badge style="aqua" %}} Informational {{% /badge %}}

FortiAIGate is not set up for this session — this section is informational only.

To route the agent through FortiAIGate instead of the local Ollama, you would change a single value:

```bash
cd ~/xperts-ai-101/lab-app/helm
helm upgrade ai101 ./ai101 -f ai101/values-lab4.yaml \
    --set agent.openaiBaseUrl=https://your-fortiaigate-host/v1
```
