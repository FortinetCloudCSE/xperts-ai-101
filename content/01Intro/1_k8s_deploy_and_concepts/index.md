---
title: "Kubernetes Fundamentals with AKS"
linkTitle: "Kubernetes Fundamentals"
weight: 2
---

All tasks for this session are completed from the bastion (the Linux VM provided for your session) and a browser.

This session starts with Kubernetes fundamentals using a managed Azure Kubernetes Service (AKS) cluster. Provided credentials give you access to the bastion, from which an AKS cluster is deployed in Azure Cloud. Using a prebuilt script, you deploy the cluster in Azure Cloud without navigating complex installation steps.

The focus areas for the Kubernetes fundamentals include **Pods**, **Labels**, **Deployments**, **Replicas**, and **Namespaces**.

## AKS Cluster Deployment

We'll start by deploying a Managed Azure Kubernetes Service (AKS). This hands-on approach introduces you to Kubernetes essentials efficiently, with the setup process completing in about 5 minutes.

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

```output
Name          Location    ResourceGroup             KubernetesVersion    CurrentKubernetesVersion    ProvisioningState    Fqdn
------------  ----------  ------------------------  -------------------  --------------------------  -------------------  ----------------------------------------------------------------
aks-aiuser10  eastus      rg-xperts-ai101-aiuser10  1.35                 1.35.7                      Succeeded            aks-aiuser-rg-xperts-ai101--02b500-u76am9is.hcp.eastus.azmk8s.io
```

## Manage Kubernetes objects

There are two primary methods for managing Kubernetes objects:

- Imperative Management: This approach uses direct kubectl commands to create, update, and delete Kubernetes resources. It's beneficial for ad-hoc development and experimentation due to its straightforward syntax. However, it might not fully leverage all Kubernetes API features and is less suited for tracking changes in version control.

- Declarative Management: This method involves defining resources in YAML or JSON manifests and managing them with commands like kubectl apply. It's ideal for production environments and version-controlled configuration, offering reproducibility and easier management of complex deployments.

While imperative commands offer a quick way to perform tasks and are excellent for learning Kubernetes, declarative management provides a more robust framework for consistent and reproducible infrastructure management.

In this task, we will explore the imperative approach using kubectl to familiarize ourselves with basic Kubernetes operations.

### Use kubectl

kubectl is already deployed and configured on the bastion.

Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To do this, use the `kubectl` command to create Pods, Deployments or other Kubernetes objects.

kubectl relies on a configuration file found at **~/.kube/config** for authentication and communication with the kube-api-server.

- Running `kubectl config view` displays details about the kube-API server, including its address, name, and the client's key and certificate.
- Running `kubectl version` displays the client **kubectl** version and server version.

### Basic usage of kubectl

The common format of a kubectl command is: <kbd>kubectl</kbd> <kbd>ACTION</kbd> <kbd>RESOURCE</kbd>

This performs the specified action (e.g., create, describe, delete) on the specified resource (e.g., node or deployment). Use --help after the subcommand to get additional info about possible parameters (e.g, kubectl get nodes --help).

Check that kubectl is configured to talk to your cluster by running `kubectl version`,
which contacts the API server:

```bash {run="bastion"}
kubectl version
```

A response with both a `Client Version` and a `Server Version` confirms kubectl
can reach the cluster.

Running `kubectl` with no arguments lists the available commands:

```bash {run="bastion"}
kubectl
```

The output is similar to:

```output {collapse="true"}
Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller
```

For example, you can use `kubectl get node` or `kubectl get node -o wide` to check cluster node detail:

```bash {run="bastion"}
kubectl get node
```

The output is similar to:

```output
NAME                             STATUS   ROLES    AGE   VERSION
aks-worker-35394522-vmss000000   Ready    <none>   17h   v1.35.7
```

## Pod

A Pod in Kubernetes is like a single instance of an application. It can hold closely related containers that work together. All containers in a Pod share the same IP address and ports, and they are always placed together on the same server (Node) in the cluster. This setup means they can easily communicate with each other.  Pods provide the environment in which containers run and offer a way to logically group containers together.

To create a Pod:

- **kubectl run**: Quick way to create a single Pod for ad-hoc tasks or debugging.
- **kubectl create**: Creates specific Kubernetes resources with more control. Use kubectl create -f to create from file.
- **kubectl apply**: Creates or updates resources based on their configuration files. Use kubectl apply -f to create from file.

### Pod Management

#### Create and Verify Pod

Create a Pod running the juiceshop container:

```bash {run="bastion"}
kubectl run juiceshop --image=bkimminich/juice-shop
```

Verify the Pod creation:

```bash {run="bastion"}
kubectl get pod
```

The output is similar to:

```output
NAME        READY   STATUS    RESTARTS   AGE
juiceshop   1/1     Running   0          27s
```

The **STATUS** of the Pod may be **ContainerCreating**, but eventually it becomes **Running**.

{{% notice style="tip" title="Checkpoint" %}}
Checkpoint: you should now have a running Pod (`juiceshop`), created directly with `kubectl run`.
{{% /notice %}}

#### Review Container Logs

Check the container logs:

```bash {run="bastion"}
kubectl logs po/juiceshop
```

The output is similar to:

```output {collapse="true"}
info: Detected Node.js version v24.19.0 (SUCCESS)
info: Detected OS linux (SUCCESS)
info: Detected CPU x64 (SUCCESS)
info: Configuration default validated (SUCCESS)
info: Entity models 21 of 21 are initialized (SUCCESS)
info: All dependencies in ./package.json are satisfied (SUCCESS)
info: Required file server.js is present (SUCCESS)
info: Required file index.html is present (SUCCESS)
info: Required file styles.css is present (SUCCESS)
info: Required file polyfills.js is present (SUCCESS)
info: Required file main.js is present (SUCCESS)
info: Required file matching /^hacking-instructor-.+\.js$/ is present (SUCCESS)
info: Port 3000 is available (SUCCESS)
info: Domain https://www.alchemy.com/ is reachable (SUCCESS)
warn: Environment variable ALCHEMY_API_KEY is not present (WARNING)
warn: "Mint the Honey Pot" challenge will not work as intended without a valid ALCHEMY_API_KEY
warn: "Wallet Depletion" challenge will not work as intended without a valid ALCHEMY_API_KEY
info: Check https://howto-web3.owasp-juice.shop for instructions on how to set up and configure the Alchemy API
warn: Domain http://localhost:11434/v1 is not reachable (WARNING)
warn: "Chatbot Prompt Injection" challenge will not work as intended without access to http://localhost:11434/v1
warn: "Greedy Chatbot Manipulation" challenge will not work as intended without access to http://localhost:11434/v1
warn: "AI Debugging" challenge will not work as intended without access to http://localhost:11434/v1
warn: "System Prompt Extraction" challenge will not work as intended without access to http://localhost:11434/v1
info: Check https://howto-llm.owasp-juice.shop for instructions on how to set up and configure the LLM API
info: Server listening on port 3000
```

#### Create Pod from yamlfile

Create a Pod from a YAML manifest with `kubectl create -f <yamlfile>`. This writes the manifest with a heredoc, then creates the Pod from it:

```bash {run="bastion"}
cat << EOF | tee juice-shop2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: juiceshop2
  labels:
    run: juiceshop2
spec:
  containers:
  - image: bkimminich/juice-shop
    name: juiceshop
EOF
kubectl create -f juice-shop2.yaml
```

`cat << EOF` is a shell syntax for a "here document" (heredoc). It allows you to provide a block of input text directly in the shell. The input continues until the token EOF (End Of File) is encountered again in the input stream.
``|`` is the pipe operator, which takes the output of the command on its left (the heredoc in this case) and uses it as the input for the command on its right. In the next following chapters, we are going to use this a lot.

Verify that both Pods are running:

```bash {run="bastion"}
kubectl get pod
```

The output is similar to:

```output
NAME         READY   STATUS    RESTARTS   AGE
juiceshop    1/1     Running   0          4m29s
juiceshop2   1/1     Running   0          22s
```

Use `kubectl delete` to delete the `juiceshop2` Pod:

```bash {run="bastion"}
kubectl delete pod juiceshop2
```

Check the Pod list again:

```bash {run="bastion"}
kubectl get pod
```

The output is similar to:

```output
NAME        READY   STATUS    RESTARTS   AGE
juiceshop   1/1     Running   0          63s
```

### Labels

Labels in Kubernetes are key/value pairs attached to objects, such as Pods, Services, and Deployments. They serve to organize, select, and group objects in ways meaningful to users, allowing the mapping of organizational structures onto system objects in a loosely coupled fashion without necessitating clients to store these mappings.

1. Labels can be utilized to filter resources when using kubectl commands. Execute the command below to retrieve all Pods labeled with run=juiceshop.

    ```bash {run="bastion"}
    kubectl get pods -l run=juiceshop
    ```

1. Labels can be added to an object using the `kubectl label` command. Execute the command below to add the key:value pair "purpose=debug" to the Pod named juiceshop.

    ```bash {run="bastion"}
    kubectl label pod juiceshop purpose=debug
    ```

#### Get Labels

To display all labels:

```bash {run="bastion"}
kubectl get pod --show-labels
```

The output is similar to:

```output
NAME        READY   STATUS    RESTARTS   AGE     LABELS
juiceshop   1/1     Running   0          8m3s    purpose=debug,run=juiceshop,topology.kubernetes.io/region=eastus,topology.kubernetes.io/zone=0
```

## Deployments

While directly creating Pods might be suitable for learning purposes or specific use cases (like one-off debugging tasks), **deployments** offer a robust and scalable way to manage containerized applications in production environments. Deployments abstract away much of the complexity associated with Pod management, providing essential features such as automatic scaling, self-healing, rolling updates, and rollbacks, which are critical for running reliable and available applications in Kubernetes.

- Deployment in Kubernetes manages app Pods, ensuring they run and update smoothly.
- Simplifies app management and scaling by handling Pods replication and updates.
- Using kubectl, you can scale Pods easily (e.g., from 1 to 10) to meet demand.
- Monitors app Pods continuously for any failures.
- Implements self-healing by replacing failed Pod on other nodes in the cluster.

### Deploying an Application

Deploy your first application on Kubernetes using the `kubectl create deployment` command. This is an imperative command, it requires specifying the deployment name and the location of the application image (including the full repository URL for images not hosted on Docker Hub).

Deploy the kubernetes-bootcamp application:

```bash {run="bastion"}
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
```

The **--image** flag chooses the container image to use for the Pod; the image here is from the gcr.io image repository.

Other image repositories can be used if you prefer to use juice-shop from Docker Hub:

- `kubectl create deployment juiceshop --image=docker.io/bkimminich/juice-shop` as Docker Hub is the default registry
- `kubectl create deployment juiceshop --image=bkimminich/juice-shop` could also be used

Congratulations! You've just deployed your first application by creating a deployment.

| Parameter | Value | Meaning |
| ----- | ----- | ----- |
| Name: | kubernetes-bootcamp | Specifies the name of the deployment |
| Image: | gcr.io/google-samples/kubernetes-bootcamp:v1 | Determines the container image to use |

By executing this command, you instruct Kubernetes to pull the specified container image, create a Pod for it, and manage its lifecycle based on the deployment's configuration. This process encapsulates the application in a scalable and manageable unit, facilitating easy updates, rollbacks, and scaling.

The `kubectl create deployment` command is used to create a new deployment in Kubernetes. Deployments manage a set of replicas of your application, ensuring that a specified number of instances (Pods) are running at any given time.

Verify the deployment:

```bash {run="bastion"}
kubectl get deployment -l app=kubernetes-bootcamp
```

There should be a single deployment running a single Pod of the app container(s), running inside a Pod with shared storage and IP. The output is similar to:

```output
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           24s
```

In the output:

- **kubernetes-bootcamp** is the name of the deployment managing your application.
- **READY 1/1** indicates that there is one **Pod** targeted by the deployment, and it is ready.
  - 1/1 means the deployment expects 1 Pod and the Pod in ready status is also 1 which means the actual deployed Pod meets the expected number (**replica**)
- **UP-TO-DATE**: Indicates the number of replicas that have been updated to achieve the desired state.
  - 1 indicates that one replica is up-to-date with the desired configuration.
- **AVAILABLE**: Shows the number of replicas that are available to serve requests.
  - 1 indicates there is one replica available.

{{% notice style="tip" title="Checkpoint" %}}
Checkpoint: you should now have a Deployment (`kubernetes-bootcamp`) managing one Pod.
{{% /notice %}}

Let's keep this deployment to explore what is **ReplicaSet**

## ReplicaSet

A **ReplicaSet** is a Kubernetes resource that ensures a specified number of replicas of a Pod are running at any given time. It is one of the key controllers used for Pod replication and management, offering both scalability and fault tolerance for applications. The primary purpose of a ReplicaSet is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods. **Deployment** is a higher-level resource in Kubernetes that actually manages ReplicaSets and provides declarative updates to applications.

Check the ReplicaSet created by the Deployment:

```bash {run="bastion"}
kubectl get rs -l app=kubernetes-bootcamp
```

The output is similar to:

```output
NAME                             DESIRED   CURRENT   READY   AGE
kubernetes-bootcamp-67fbdd6b79   1         1         1       111s
```

Check the ReplicaSet's details:

```bash {run="bastion"}
kubectl describe rs kubernetes-bootcamp
```

The output is similar to:

```output {collapse="true"}
Name:           kubernetes-bootcamp-67fbdd6b79
Namespace:      default
Selector:       app=kubernetes-bootcamp,pod-template-hash=67fbdd6b79
Labels:         app=kubernetes-bootcamp
                pod-template-hash=67fbdd6b79
Annotations:    deployment.kubernetes.io/desired-replicas: 1
                deployment.kubernetes.io/max-replicas: 2
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/kubernetes-bootcamp
Replicas:       1 current / 1 desired
Pods Status:    1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=kubernetes-bootcamp
           pod-template-hash=67fbdd6b79
  Containers:
   kubernetes-bootcamp:
    Image:         gcr.io/google-samples/kubernetes-bootcamp:v1
    Port:          <none>
    Host Port:     <none>
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
```

In the output, the line **Controlled By:  Deployment/kubernetes-bootcamp** indicates that ReplicaSet is controlled by Deployment/kubernetes-bootcamp.

## Manage your Deployment

### Scale the Application

Scale out the deployment to 10 replicas:

```bash {run="bastion"}
kubectl scale deployment kubernetes-bootcamp --replicas=10
```

Verify the scale-out:

```bash {run="bastion"}
kubectl get deployment kubernetes-bootcamp
```

The output is similar to:

```output
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          4m11s
```

The **READY** status eventually shows 10/10, indicating that 10 replicas were expected and all 10 are now available.

Use `kubectl get pod` with `-l` to list the Pods created by the deployment (**app=kubernetes-bootcamp** is the label assigned to the Pods on creation); you should see 10 Pods:

```bash {run="bastion"}
kubectl get pod -l app=kubernetes-bootcamp
```

The output is similar to:

```output
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-67fbdd6b79-2k5r9   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-6hxbn   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-77qm7   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-b4h8m   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-ccwb8   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-grrcw   1/1     Running   0          4m54s
kubernetes-bootcamp-67fbdd6b79-jswkp   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-wb6xw   1/1     Running   0          53s
kubernetes-bootcamp-67fbdd6b79-wv29h   1/1     Running   0          52s
kubernetes-bootcamp-67fbdd6b79-z4bm2   1/1     Running   0          52s
```

To reduce resource usage, scale the deployment back in to 1 replica, decreasing the expected number of Pods:

```bash {run="bastion"}
kubectl scale deployment kubernetes-bootcamp --replicas=1
```

Verify the scale-in:

```bash {run="bastion"}
kubectl get pod -l app=kubernetes-bootcamp -o wide
```

Some Pods will be in the **Terminating** state, and eventually only 1 Pod remains active. The output is similar to:

```output
NAME                                   READY   STATUS    RESTARTS   AGE     IP            NODE                             NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-67fbdd6b79-grrcw   1/1     Running   0          7m29s   10.224.0.14   aks-worker-35394522-vmss000000   <none>           <none>
```

Above output is from the `kubectl get pod -l app=kubernetes-bootcamp -o wide` command, which requests Kubernetes to list Pods with additional information (wide output) that match the label app=kubernetes-bootcamp. Here's a breakdown of the output:

- **NAME**: kubernetes-bootcamp-bcbb7fc75-5r649 - This is the name of the Pod. Kubernetes generates Pod names automatically based on the deployment name and a unique identifier to ensure each Pod within a namespace has a unique name with an appended hash value bcbb7fc75-5r649, this is created by **deployment** automatically for each replica. Pods created with `kubectl run pod` or `kubectl create -f <pod.yaml>` does not have this hash appended in Pod name.

- **READY**: 1/1 - This indicates the readiness state of the Pod. It means that 1 out of 1 container within the Pod is ready. Readiness is determined by readiness probes, which are used to know when a container is ready to start accepting traffic.

- **STATUS**: Running - This status indicates that the Pod is currently running without issues.

- **RESTARTS**: 0 - This shows the number of times the containers within the Pod have been restarted. A restart usually occurs if the container exits with an error or is killed for some other reason. In this case, 0 restarts indicate that the Pod has been stable since its creation. if Pod crashed for some reason, kube-manager will restart it, then the RESTARTS will change.

- **AGE**: 73s - This shows how long the Pod has been running. In this case, the Pod has been up for 73 seconds.

- **IP**: 10.244.222.16 - This is the internal IP address assigned to the Pod within the Kubernetes cluster network. This IP is used for communication between Pods within the cluster.

- **NODE**: worker001 - This indicates the name of the node (physical or virtual machine) within the Kubernetes cluster on which this Pod is running. The scheduler decides the placement of Pods based on various factors like resources, affinity/anti-affinity rules, etc. In this case, the Pod is running on a node named worker001.

Below diagram shows a Pod can have 1 container or multiple containers, with or without shared storage.

All the containers within a single Pod in Kubernetes follow  "shared fate" principle. This means that containers in a Pod are scheduled on the same node (physical or virtual machine) and share the same lifecycle, network namespace, IP address, and storage volumes.

![pods](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_pods.svg)

## Namespace

A namespace in Kubernetes is like a folder that helps you organize and separate your cluster's resources (like applications, services, and Pods) into distinct groups. It's useful for managing different projects, environments (such as development, staging, and production), or teams within the same Kubernetes cluster. Namespaces help avoid conflicts between names and make it easier to apply policies, limits, and permissions on a per-group basis

- Understand the default namespace

By default, a Kubernetes cluster will instantiate a default namespace when provisioning the cluster to hold the default set of Pods, Services, and Deployments used by the cluster.

- we can use `kubectl create namespace` to create different namespace name. use `kubectl get namespace` to list all namespaces in cluster.

- by default, all operation is under default namespace, for example `kubectl get deployment kubernetes-bootcamp -n default` is same as `kubectl get deployment kubernetes-bootcamp`.

Imagine a scenario where an organization is using a shared Kubernetes cluster for development and production use cases.

The development team would like to maintain a space in the cluster where they can get a view on the list of Pods, Services, and Deployments they use to build and run their application. In this space, Kubernetes resources come and go, and the restrictions on who can or cannot modify resources are relaxed to enable agile development.

The operations team would like to maintain a space in the cluster where they can enforce strict procedures on who can or cannot manipulate the set of Pods, Services, and Deployments that run the production site.

One pattern this organization could follow is to partition the Kubernetes cluster into two namespaces: development and production.

### Create deployment in namespace

Follow the steps below to explore how namespaces organize your deployments in Kubernetes. Execute each command sequentially.

Create two namespaces:

```bash {run="bastion"}
kubectl create namespace production
kubectl create namespace development
```

Verify the namespaces were created:

```bash {run="bastion"}
kubectl get namespace production
kubectl get namespace development
```

Deploy the same application into each namespace:

```bash {run="bastion"}
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=production
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=development
```

Monitor each deployment's rollout progress:

```bash {run="bastion"}
kubectl rollout status deployment kubernetes-bootcamp -n development
kubectl rollout status deployment kubernetes-bootcamp -n production
```

Check the deployment and Pod details in each namespace:

```bash {run="bastion"}
kubectl get deployment kubernetes-bootcamp -n development
kubectl get deployment kubernetes-bootcamp -n production
kubectl get pod --namespace=production
kubectl get pod -n=development
```

Or use `kubectl get all -n=production` and `kubectl get all -n=development` to list everything in that namespace.

{{% notice style="tip" title="Checkpoint" %}}
Checkpoint: you should now have identical `kubernetes-bootcamp` Deployments and Pods isolated in two Namespaces (`production` and `development`).
{{% /notice %}}

Delete the namespaces and everything inside them. This takes a while — ***do not interrupt*** the deletion process:

```bash {run="bastion"}
kubectl delete namespace production
kubectl delete namespace development
```

## How this connects to the AI labs

Everything above — Pods, Deployments, Namespaces — is what you'll see again as soon as you install the `ai101` Helm chart in the next section. Each of Ollama, the agent, the MCP server and the UI runs as its own **Deployment** (which manages a **Pod**), and each is fronted by its own **Service** — a kind of object this section didn't create by hand, but Helm does, one per component. The chart also creates a PersistentVolumeClaim for Ollama's model storage, a ConfigMap for the UI's nginx config, and (if you enable it) an Ingress. All of it lands in the `default` **Namespace** (the same one you already worked in above) unless you override it. Helm itself stores each release's state in a Kubernetes Secret — that's Helm 3's own bookkeeping, not a chart-authored object.

### Review Questions

1. Explain the role of a Deployment in Kubernetes. How does it simplify the process of scaling and managing application within the cluster?
{{% expand title="Click for Answer..." %}}
  Deployments in Kubernetes simplify application management by providing a high-level abstraction for deploying, scaling, and updating applications. Kubernetes handles the complexities of maintaining desired state, scaling, and rolling updates, allowing developers and operators to focus on the application rather than the infrastructure details.
{{% /expand %}}

1. How do namespaces contribute to resource management and isolation in a Kubernetes cluster? Provide an example scenario where separating resources into different namespaces would be beneficial.
{{% expand title="Click for Answer..." %}}
Namespaces provide a clean separation between different clients, enhancing security, resource management, and operational efficiency. Namespaces allow the SaaS provider to manage a multi-tenant environment effectively within a single Kubernetes cluster.
For example, Deploying a firewall container in a separate namespace within Kubernetes cluster offers several benefits:

- Ensures that only authorized team members can modify firewall rules.
- Apply strict resource quotas to guarantee the firewall always has necessary resources.
- Implement network policies that allow the firewall to interact with all namespaces while restricting other cross-namespace communication.
- Perform updates to the firewall components without risking downtime for tenant applications.
{{% /expand %}}

1. Describe how containers are organized within a Pod in Kubernetes and explain the advantages of this arrangement for container communication and resource sharing.
{{% expand title="Click for Answer..." %}}

- Network Sharing:
  - All containers in a Pod share a single IP address
  - They can communicate with each other using localhost
  - Containers use different ports on the shared network interface
    - Example: Container A can reach Container B via localhost:port</br></br>

- Storage Sharing:
  - Pods can have one or more volumes defined
  - Volumes can be mounted into some or all containers in the Pod
  - Containers can read from and write to these shared volumes
    - Example: A shared volume mounted at /data in two containers allows containers to exchange files

This shared network and storage setup enables efficient inter-container communication and data exchange within the Pod, facilitating tight integration of related application components.
{{% /expand %}}
