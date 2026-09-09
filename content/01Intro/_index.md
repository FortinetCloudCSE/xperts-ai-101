---
title: "Session Overview"
linkTitle: "Overview"
weight: 10
---

## Your session steps

1. Deploy a Managed Kubernetes Service (AKS) on Azure.

    - kubectl, helm and jq are already installed

1. Run through the Kubernetes overview and concepts

1. Deploy lab applications to a the AKS cluster with Helm as each lab describes.

## Lab Stack overview

The lab application is four containers wired together with Helm
for Kubernetes, each lab adds one layer:

```mermaid
flowchart TD
    L1[Lab 1<br>Ollama only] --> L2[Lab 2<br>Agent + UI]
    L2 --> L3[Lab 3<br>MCP Server]
    L3 --> L4[Lab 4<br>same stack<br>different env vars]
```

The single configuration value that controls which LLM the agent talks to is
`OPENAI_BASE_URL`. By default it points at the local Ollama container. If you
want to route through FortiAIGate instead, that is the only value you change —
the agent image, MCP server, and UI are identical.
