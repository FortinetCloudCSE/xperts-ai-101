#!/usr/bin/env bash
# Reset the workshop to a fresh state so the labs can be re-run from Lab 1
#
# Stops the port-forwards, uninstalls the ai101 Helm release (agent, MCP server,
# UI and Ollama), and deletes the Ollama model volume. Re-install the Lab 1 chart
# afterwards (Kubernetes / Helm Setup, step 2) to start again.
#
# Usage:
#   ./reset_labs.sh

RELEASE="${RELEASE:-ai101}"

pkill -f "port-forward svc/${RELEASE}-" && echo "Stopped port-forwards"
rm -f /tmp/${RELEASE}-*-port-forward.log

if helm status "$RELEASE" >/dev/null 2>&1; then
  helm uninstall "$RELEASE" --wait
else
  echo "Helm release $RELEASE is not installed"
fi

kubectl delete pvc "${RELEASE}-ollama-data" --ignore-not-found

echo
echo "Remaining ${RELEASE} resources (expect none):"
kubectl get all,pvc -l "app.kubernetes.io/instance=${RELEASE}"
