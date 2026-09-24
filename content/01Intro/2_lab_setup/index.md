---
title: "Kubernetes / Helm Setup"
linkTitle: "Kubernetes / Helm"
weight: 3
---

## Prerequisites

kubectl, Helm and jq are already installed on the bastion (the Linux VM provided for your session). The table below is for reference — you don't need to install anything.

| Requirement | Version | Check |
| ------------- | --------- | ------- |
| kubectl | 1.28+ | `kubectl version --client` |
| Helm | 3.14+ | `helm version` |
| jq | 1.6+ | `jq --version` |
| A running cluster | — | `kubectl cluster-info` |
| Default StorageClass | — | `kubectl get storageclass` |

## 1. Verify Kubernetes access

Confirm kubectl is pointed at your cluster:

```bash {run="bastion"}
kubectl config current-context
```

List the cluster nodes:

```bash {run="bastion"}
kubectl get nodes
```

If `kubectl get nodes` works, you are connected to the cluster and can continue to the Clone the repo step.

## 2. Clone the repo

The repo is hosted on GitHub and supplies Helm with the settings for each lab environment, plus the code that runs the AI components of the labs.

```bash {run="bastion"}
cd ~
git clone https://github.com/FortinetCloudCSE/xperts-ai-101.git
```

## 3. Install the chart for Lab 1

Pre-built multi-arch images (amd64 + arm64) are published to GitHub Container Registry (GHCR) and pulled automatically by the cluster — no manual image pull required.

Install the Lab 1 chart, which deploys Ollama only:

```bash {run="bastion"}
cd ~/xperts-ai-101/lab-app/helm
helm upgrade --install ai101 ./ai101 -f ai101/values-lab1.yaml
```

The output is similar to:

```output
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

```output
NAME                           READY   STATUS    RESTARTS   AGE
ai101-ollama-8699cc758-sqrgt   1/1     Running   0          12m
```

Once the `ai101-ollama-*` pod shows `Running`, follow its logs to confirm the model download completed. This command streams continuously — stop it with <kbd>Ctrl</kbd>+<kbd>C</kbd> when you're done:

```bash {run="bastion"}
kubectl logs -l app.kubernetes.io/component=ollama -f
```

The output is similar to:

```output
[GIN] 2026/07/14 - 18:49:21 | 200 |     410.443µs |       127.0.0.1 | GET      "/api/tags"
[GIN] 2026/07/14 - 18:49:21 | 200 |     431.543µs |       127.0.0.1 | GET      "/api/tags"
[GIN] 2026/07/14 - 18:49:31 | 200 |      45.616µs |       127.0.0.1 | HEAD     "/"
[GIN] 2026/07/14 - 18:49:31 | 200 |     334.521µs |       127.0.0.1 | GET      "/api/tags"
[GIN] 2026/07/14 - 18:49:41 | 200 |      23.003µs |       127.0.0.1 | HEAD     "/"
```

## 4. Verify

Port-forward the Ollama service so the bastion can reach the Ollama API running inside the Kubernetes cluster. This backgrounds the port-forward with `&` so it keeps running:

```bash {run="bastion"}
kubectl port-forward svc/ai101-ollama 11434:11434 > /tmp/ai101-ollama-port-forward.log 2>&1 < /dev/null &
```

Send a test prompt to the Ollama OpenAI-compatible API endpoint:

```bash {run="bastion"}
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen2.5:3b","messages":[{"role":"user","content":"ping"}]}' \
  | jq -r '.choices[0].message.content'
```

If the command returns a text response, Ollama is running and the model is able to perform inference. The output is similar to:

```output
Pong! Your ping request was successfully answered. How can I assist you further?
```

The `kubectl port-forward` command creates a temporary connection from `localhost:11434` to the Ollama service running inside the Kubernetes cluster. The `curl` command then sends a small test prompt to that local endpoint. Kubernetes forwards the request to Ollama, Ollama runs the model, and the model response is returned to the bastion.

## 5. Reference — upgrade per lab

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

## 6. FortiAIGate routing

FortiAIGate is not set up for this session — this section is informational only.

To route the agent through FortiAIGate instead of the local Ollama, you would change a single value:

```bash
cd ~/xperts-ai-101/lab-app/helm
helm upgrade ai101 ./ai101 -f ai101/values-lab4.yaml \
    --set agent.openaiBaseUrl=https://your-fortiaigate-host/v1
```
