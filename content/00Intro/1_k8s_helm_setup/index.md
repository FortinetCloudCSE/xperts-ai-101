---
title: "Kubernetes & Helm Setup"
linkTitle: "Kubernetes & Helm Setup"
weight: 1
---

All tasks for this session are completed from the bastion (the Linux VM provided for your session) and a browser.

This page is **required**. You deploy an Azure Kubernetes Service (AKS) cluster, then use Helm to install the Lab 1 chart and confirm it works. Every later lab builds on this setup. Setup takes roughly 20–30 minutes, about 5 of them waiting for the AKS cluster to deploy.

## Prerequisites

kubectl, Helm and jq are already installed on the bastion (the Linux VM provided for your session). The table below is for reference — you don't need to install anything.

| Requirement | Version | Check | Purpose
| ------------- | --------- | ------- | -----
| kubectl | 1.28+ | `kubectl version --client` | Managing K8S clusters
| Helm | 3.14+ | `helm version` | Package manager automating the creation, packaging, configuration, and deployment of application
| jq | 1.6+ | `jq --version` | lightweight and flexible command-line JSON processor used to slice, filter, map, and transform the highly detailed JSON data returned by the Kubernetes API
| Running cluster | — | `kubectl cluster-info` | Get info on an existing cluster

## 1. AKS Cluster Deployment {{% badge style="red" %}} REQUIRED {{% /badge %}}

You'll start by logging into you assigned linux VM and deploying a Managed Azure Kubernetes Service (AKS).

{{% notice style="info" title="Login Information" %}}

- Login to your assigned linux VM using the Bastion host link you received from the instructors
- User the username password combination `aiuser` and `123Password$%^!`
- While all users have the same login credentials the Bastion host link will connect to your uniquely assigned linux VM
- Should you require assistance from the instructors, the name of the linux VM will be in the browser tab

{{% /notice %}}

The script below creates a Managed Azure Kubernetes Service (AKS) with one worker node and updates the local `kubeconfig` for AKS access. The script is pre-installed on the bastion and uses the Azure credentials already configured there, so you don't need to sign in to Azure yourself.

Run the script, then check its output against the expected output below it.

All commands used throughout this session are tailored to your session environment.

```bash {run="bastion"}
./aks-create.sh
```

The output is similar to:

```output {collapse="true"}
{
  "aadProfile": null,
  [...]
  "agentPoolProfiles": [
    {
      "count": 1,
      "name": "worker",
      "mode": "System",
      "vmSize": "Standard_D8ads_v5",
      "osType": "Linux",
      "provisioningState": "Succeeded",
      [...]
    }
  ],
  [...]
  "currentKubernetesVersion": "1.35.7",
  "disableLocalAccounts": false,
  "diskEncryptionSetId": null,
  "dnsPrefix": "aks-aiuser-rg-xperts-ai101--02b500",
  [...]
  "fqdn": "aks-aiuser-rg-xperts-ai101--02b500-u76am9is.hcp.eastus.azmk8s.io",
  [...]
  "name": "aks-aiuser10",
  [...]
  "nodeResourceGroup": "MC_rg-xperts-ai101-aiuser10_aks-aiuser10_eastus",
  [...]
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "rg-xperts-ai101-aiuser10",
  [...]
}
Merged "aks-aiuser10" as current context in /home/aiuser/.kube/config
Cluster  Created.
```

Verify the provisioned AKS cluster:

```bash {run="bastion"}
az aks list --resource-group ${RESOURCE_GROUP_NAME} --output table
```

The output is similar to:

```output {collapse="true"}
Name          Location    ResourceGroup             KubernetesVersion    CurrentKubernetesVersion    ProvisioningState    Fqdn
------------  ----------  ------------------------  -------------------  --------------------------  -------------------  ----------------------------------------------------------------
aks-aiuser10  eastus      rg-xperts-ai101-aiuser10  1.35                 1.35.7                      Succeeded            aks-aiuser-rg-xperts-ai101--02b500-u76am9is.hcp.eastus.azmk8s.io
```

## 2. Verify Kubernetes access {{% badge style="red" %}} REQUIRED {{% /badge %}}

Confirm kubectl is pointed at your cluster:

```bash {run="bastion"}
kubectl config current-context
```

List the cluster nodes:

```bash {run="bastion"}
kubectl get nodes
```

```output {collapse="true" hl_lines="7 9"}
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

## 3. Install the chart for Lab 1 {{% badge style="red" %}} REQUIRED {{% /badge %}}

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

## 4. Verify {{% badge style="red" %}} REQUIRED {{% /badge %}}

Ollama listens on a port inside the cluster that the bastion can't reach directly, so a **port-forward** (a temporary tunnel from the bastion into the cluster) is needed. The command below backgrounds the tunnel with `&` so it keeps running while you do other things:

```bash {run="bastion"}
kubectl port-forward svc/ai101-ollama 11434:11434 > /tmp/ai101-ollama-port-forward.log 2>&1 < /dev/null &
```

{{% notice style="warning" title="If you lose your Linux session connection" %}}
If your connection to the Linux session (the bastion) drops, the background port-forward dies with it. Re-run the same `kubectl port-forward` command above to restart it before continuing.
{{% /notice %}}

Send a test prompt to the Ollama OpenAI-compatible API endpoint (the same HTTP request format OpenAI's API uses, so most AI tools can talk to it). A **prompt** is the text you send to the model. This one is just a user message ("ping") with no system prompt. The request is wrapped in a small script, [`ping_ollama.sh`](https://github.com/FortinetCloudCSE/xperts-ai-101/blob/main/lab-app/scripts/ping_ollama.sh), so you don't have to paste a long `curl` command. The script was added after some environments were provisioned, so first pull the latest changes to the repo:

```bash {run="bastion"}
git -C ~/xperts-ai-101 pull
```

Then run the script:

```bash {run="bastion"}
~/xperts-ai-101/lab-app/scripts/ping_ollama.sh
```

{{% badge style="green" %}} Note {{% /badge %}} If the command returns a text response, Ollama is running and the model is able to perform inference. The output is similar to:

```output {collapse="true"}
Pong! Your ping request was successfully answered. How can I assist you further?
```

**What you just saw:** `kubectl port-forward` created a temporary connection from `localhost:11434` to the Ollama service inside the cluster. The script sent a small test prompt to that local endpoint, Kubernetes forwarded it to Ollama, Ollama ran the model, and the reply came back to the bastion. Every lab builds on this path, so if later commands fail with "connection refused", the port-forward is the first thing to check. The model's wording will differ on each run.

## 5. Reference — upgrade per lab {{% badge style="aqua" %}} Informational {{% /badge %}}

Each lab tells you which of these to run to set up for its exercises. This is for reference only — run only the command for the lab you're on:

{{% notice style="tip" title="Lab update progression" %}}

cd ~/xperts-ai-101/lab-app/helm

### Lab 1 — Ollama only (already done above)

helm upgrade --install ai101 ./ai101 -f ai101/values-lab1.yaml

### Lab 2 — Agent (hardcoded tools) + UI

helm upgrade --install ai101 ./ai101 -f ai101/values-lab2.yaml

### Lab 3 — Agent (MCP mode) + MCP server + UI

helm upgrade --install ai101 ./ai101 -f ai101/values-lab3.yaml

### Lab 4 — Same as lab3 (security demo steps use env overrides)

helm upgrade --install ai101 ./ai101 -f ai101/values-lab4.yaml

{{% /notice %}}

### Troubleshooting: check your Helm revision

Every `helm upgrade` adds one **revision** to the `ai101` release. If a lab behaves like the wrong lab (a missing UI, a missing MCP server, tools that don't match), check which revision is running and whether the last upgrade succeeded:

```bash {run="bastion"}
helm history ai101
```

The last row is what is running now. Its `STATUS` must be `deployed`; every earlier row reads `superseded`. A last row of `failed` means that upgrade did not complete, so re-run the lab's `helm upgrade` command. Each `DESCRIPTION` reads `Install complete` for revision 1 and `Upgrade complete` after that.

If you ran each Helm command in the labs once, in order, the last revision at each point is:

| After this step | Last revision | Values applied
| --- | --- | ---
| 3. Install the chart for Lab 1 (this page), and all of Lab 1 | 1 | `values-lab1.yaml`
| Lab 2, Deploy | 2 | `values-lab2.yaml`
| Lab 3, Deploy | 3 | `values-lab3.yaml`
| Lab 3, Step 3 (enable the third tool) | 4 | `values-lab3.yaml` plus `mcpServer.enableExtraTool=true`
| Lab 4, Deploy | 5 | `values-lab4.yaml`
| Lab 4, Step 2 (quiet transparency) | 6 | `values-lab4.yaml` plus `agent.transparency=quiet`
| Lab 4, Step 4 (tool poisoning) | 7 | `values-lab4.yaml` plus `mcpServer.enableExtraTool=true` and `mcpServer.poisonDesc=true`

Higher numbers are fine if you re-ran a command. What matters is that the last row is `deployed` and the most recent upgrade matches the lab you are on. After the last step of Lab 4, the history looks similar to this (the dates will differ):

```output {collapse="true" hl_lines="8"}
REVISION  UPDATED                   STATUS      CHART        APP VERSION  DESCRIPTION
1         Tue Jul 14 18:35:02 2026  superseded  ai101-0.1.0  0.1.0        Install complete
2         Tue Jul 14 19:08:11 2026  superseded  ai101-0.1.0  0.1.0        Upgrade complete
3         Tue Jul 14 19:31:27 2026  superseded  ai101-0.1.0  0.1.0        Upgrade complete
4         Tue Jul 14 19:44:03 2026  superseded  ai101-0.1.0  0.1.0        Upgrade complete
5         Tue Jul 14 20:02:55 2026  superseded  ai101-0.1.0  0.1.0        Upgrade complete
6         Tue Jul 14 20:15:18 2026  superseded  ai101-0.1.0  0.1.0        Upgrade complete
7         Tue Jul 14 20:29:46 2026  deployed    ai101-0.1.0  0.1.0        Upgrade complete
```

### Reset to a fresh state (optional)

To run the labs again from Lab 1, or to see exactly what each lab added to the cluster, remove everything this workshop installed and start over. The reset script is [`reset_labs.sh`](https://github.com/FortinetCloudCSE/xperts-ai-101/blob/main/lab-app/scripts/reset_labs.sh). It was added after some environments were provisioned, so first pull the latest changes to the repo:

```bash {run="bastion"}
git -C ~/xperts-ai-101 pull
```

Then run the script. It stops the port-forwards and runs `helm uninstall ai101`, which removes the agent, MCP server, UI and Ollama along with the storage that holds the downloaded model (`ai101-ollama-data`). It then runs `kubectl delete pvc ai101-ollama-data --ignore-not-found` as a safety net, which normally has nothing left to delete. You can read the script first to see exactly what it does:

```bash {run="bastion"}
~/xperts-ai-101/lab-app/scripts/reset_labs.sh
```

The output ends with a list of remaining `ai101` resources, which should be empty.

To start again, repeat step 3 (install the chart for Lab 1) and step 4 (verify) above. The model is downloaded again, so allow about a minute before it is ready.

{{% notice style="tip" title="Keep it running" %}}
Leave the release running as you work through the labs. Each lab section tells you which values file to upgrade to. Only uninstall when you are completely done.
{{% /notice %}}

---

## 6. FortiAIGate routing {{% badge style="aqua" %}} Informational {{% /badge %}}

FortiAIGate is not set up for this session — this section is informational only.

To route the agent through FortiAIGate instead of the local Ollama, you would change a single value:

{{% notice style="tip" title="How would FortiAIGate be added" %}}
cd ~/xperts-ai-101/lab-app/helm
helm upgrade ai101 ./ai101 -f ai101/values-lab4.yaml \
    --set agent.openaiBaseUrl=https://your-fortiaigate-host/v1

{{% /notice  %}}
