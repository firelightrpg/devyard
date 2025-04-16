#!/bin/bash
set -e

# Add Prometheus Community repository and update
echo "Adding Prometheus Community Helm repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || echo "Repository already exists."
helm repo update

# Upgrade/Install Prometheus
echo "Deploying/Upgrading Prometheus..."
helm upgrade --install prometheus prometheus-community/prometheus --namespace default

# Add Grafana repository and update
echo "Adding Grafana Helm repository..."
helm repo add grafana https://grafana.github.io/helm-charts || echo "Repository already exists."
helm repo update

# Upgrade/Install Grafana
echo "Deploying/Upgrading Grafana..."
helm upgrade --install grafana grafana/grafana --namespace default

# Upgrade/Install Loki & Promtail
echo "Deploying/Upgrading Loki & Promtail..."
helm upgrade --install loki grafana/loki-stack --namespace default

# Add OpenTelemetry repository and update
echo "Adding OpenTelemetry Helm repository..."
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts || echo "Repository already exists."
helm repo update

# Upgrade/Install OpenTelemetry Collector with required overrides
echo "Deploying/Upgrading OpenTelemetry Collector..."
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --set image.repository=otel/opentelemetry-collector \
  --set mode=deployment \
  --set resources.limits.memory=512Mi \
  --set resources.limits.cpu=250m \
  --set resources.requests.memory=256Mi \
  --set resources.requests.cpu=100m \
  --namespace default

# Upgrade/Install the client app
echo "Deploying/Upgrading the 'client' app..."
helm upgrade --install client ./charts/service \
  --set name=client \
  --set env[0].name=APP_NAME \
  --set env[0].value=client \
  --namespace default

# Upgrade/Install the delivery app
echo "Deploying/Upgrading the 'delivery' app..."
helm upgrade --install delivery ./charts/service \
  --set name=delivery \
  --set env[0].name=APP_NAME \
  --set env[0].value=delivery \
  --namespace default

echo "All Helm upgrades/installations have been deployed successfully."
