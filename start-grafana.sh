#!/bin/bash
# start-grafana.sh: Automates port forwarding for Grafana and exports the admin password.

# Get the Grafana pod name in the default namespace.
POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")

# Check if we got a pod name.
if [ -z "$POD_NAME" ]; then
  echo "Error: No Grafana pod found in namespace 'default'."
  exit 1
fi

# Retrieve the Grafana admin password from the Kubernetes secret.
GRAFANA_PASSWORD=$(kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

# Check if the password was successfully retrieved.
if [ -z "$GRAFANA_PASSWORD" ]; then
  echo "Error: Failed to retrieve Grafana admin password."
  exit 1
fi

# Export the Grafana admin password as an environment variable.
export GRAFANA_ADMIN_PASSWORD="$GRAFANA_PASSWORD"
echo "Grafana admin password stored in environment variable GRAFANA_ADMIN_PASSWORD"
echo $GRAFANA_ADMIN_PASSWORD

# Start port forwarding from the Grafana pod to localhost:3000.
echo "Port forwarding from Grafana pod $POD_NAME to localhost:3000..."
kubectl --namespace default port-forward "$POD_NAME" 3000:3000 &
kubectl port-forward svc/loki-gateway 3100:80 &
