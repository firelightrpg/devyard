# k8loglab: A Local Kubernetes Playground for Logging

k8loglab is designed as a lightweight environment to experiment with and manage your logging stack.
This guide describes setting up k8loglab on macOS using Homebrew and Rancher Desktop.

See [**RANCHER**](./RANCHER.md) first.

---

## Table of Contents

- [Overview](#overview)
- [Configure Your Logging Stack](#configure-your-logging-stack)
- [Post-Installation: Accessing Grafana](#post-installation-accessing-grafana)
- [Troubleshooting](#troubleshooting)

---

## Overview

**k8loglab** provides a localized Kubernetes environment that helps you quickly deploy and test
components of your logging stack. The stack includes:
- **Prometheus** – for monitoring and alerting
- **Grafana** – for visualizing metrics
- **Loki** – for aggregating and querying logs
  - **Promtail** – for collecting logs (bundled with Loki)
- **OTEL (OpenTelemetry)** – for tracing and observability
- **New Relic** – for cloud-based performance monitoring and analytics
- **Sumo Logic** – for comprehensive log management and analysis
- **Splunk** – for unified log aggregation and IT operations analytics

By leveraging Rancher Desktop on macOS, you can emulate a Kubernetes cluster locally and
experiment with these components in a streamlined manner.

---

## Configure Your Logging Stack

### Prometheus – Monitoring & Alerting

[**Prometheus**](https://prometheus.io/docs/introduction/overview/) is a powerful, open-source monitoring and
alerting toolkit designed for reliability and scalability. It collects metrics as time-series data,
offers a flexible query language (PromQL) to analyze these metrics, and can trigger alerts based on
defined thresholds, making it a key component for monitoring cloud-native applications and Kubernetes
clusters.

Add the Prometheus Community repository, update, and install Prometheus.
```bash
helm repo add --force-update prometheus-community https://prometheus-community.github.io/helm-charts
```
```bash
helm repo update
helm upgrade --install prometheus prometheus-community/prometheus
```

### Grafana – Dashboard Visualization

[**Grafana**](https://grafana.com/docs/) is an open-source platform for data visualization and monitoring.
It connects to various data sources, enabling users to create interactive dashboards and graphs that
display time-series data, making it ideal for tracking application performance and infrastructure health.

Add the Grafana repository, update, and install Grafana.
```bash
helm repo add --force-update grafana https://grafana.github.io/helm-charts
```
```bash
helm repo update
helm upgrade --install grafana grafana/grafana
```

### Loki & Promtail – Log Aggregation

[**Loki**](https://grafana.com/docs/loki/latest/) is an open-source, horizontally scalable log aggregation
system designed to efficiently store and query log data using minimal indexing. It’s built to work
seamlessly with cloud-native environments, particularly Kubernetes, and offers a cost-effective
solution for centralized logging.

Install Loki. **Note:** We are loading loki.yaml to use the filesystem as a data source. A typical setup will load from a cloud source.
```bash
helm repo update
helm upgrade --install loki grafana/loki -f loki.yaml
```

[**Promtail**](https://grafana.com/docs/loki/latest/send-data/promtail/) is an agent that collects log
data from various sources (like container logs) and ships it to Loki. It enriches logs with metadata
(especially from Kubernetes) to facilitate powerful querying and log correlation in Loki. Promtail automatically collects logs from all containers that write to stdout/stderr. No code changes or file-based logging is required for your services to appear in Loki.

Install promtail.
```bash
helm upgrade --install promtail grafana/promtail \
  --set loki.serviceName=loki-gateway \
  --set loki.servicePort=80 \
  --set config.clients[0].url=http://loki-gateway.default.svc.cluster.local/loki/api/v1/push \
  --set config.clients[0].tenant_id=foo
```

### OTEL (OpenTelemetry Collector) – Distributed Tracing

**[OTEL](https://opentelemetry.io/docs/)** is an open-source observability framework designed to generate,
collect, and manage telemetry data—such as metrics, logs, and traces—from distributed systems. It
provides standardized APIs and instrumentation tools that help developers monitor application
performance and troubleshoot issues.

Add the OpenTelemetry repository, update, and install the OpenTelemetry Collector with resource
settings.
```bash
helm repo add --force-update open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```
```bash
helm repo update
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --set image.repository=otel/opentelemetry-collector \
  --set mode=deployment \
  --set resources.limits.memory=512Mi \
  --set resources.limits.cpu=250m \
  --set resources.requests.memory=256Mi \
  --set resources.requests.cpu=100m
```

### New Relic – Cloud-Based Monitoring

**[New Relic](https://docs.newrelic.com)** is a cloud-based observability platform that delivers real-time
insights into application performance, infrastructure, and user experience. It consolidates data
from logs, metrics, traces, and events, helping teams monitor, troubleshoot, and optimize their systems
effectively.

Add the New Relic repository, update, and install the New Relic integration using a dummy license key
for demonstration.

**Note:** This will install the chart, but the services will go into CrashLoopBackOff, as the license is not
valid. You may want to skip this for now.
```bash
helm repo add --force-update newrelic https://helm-charts.newrelic.com
```
```bash
helm repo update
helm upgrade --install newrelic newrelic/nri-bundle \
  --set global.licenseKey="DUMMY_LICENSE_KEY" \
  --set global.cluster="local-cluster"
```

### Sumo Logic – Cloud Log Collection

**[Sumo Logic](https://help.sumologic.com)** is a cloud-based machine data analytics platform that collects and
analyzes logs, metrics, and events from your infrastructure and applications in real time. It helps teams
gain operational insights, diagnose issues, and improve overall performance through powerful search,
visualization, and alerting capabilities.

Add the Sumo Logic repository, update, and install the Sumo Logic Kubernetes Collection using dummy
credentials for demonstration.

**Note:** This is an example where the release name (**sumologic**) and the chart reference
(**sumologic-kubernetes-collection**) are different. Further, Helm allows you to name the deployment. While
Helm allows this flexibility, a best practice is to have the deployment, release name and chart reference the
same.

**Also note:** This installation timed out for me. You may not be able to install without a valid license.
The documentation recommends a trial license, so we may need that at some point, but it starts a trial clock, so
don't get one yet. You may wish to skip this for now.
```bash
helm repo add --force-update sumologic https://sumologic.github.io/sumologic-kubernetes-collection
```
```bash
helm repo update
helm upgrade --install sumologic sumologic/sumologic \
  --set sumologic.accessId="DUMMY_ACCESS_ID" \
  --set sumologic.accessKey="DUMMY_ACCESS_KEY"
```

### Splunk – Log and Metrics Collection

**[Splunk](https://docs.splunk.com)** is a powerful platform for searching, monitoring, and analyzing
machine-generated data. It enables organizations to collect, index, and visualize data from various sources,
supporting use cases such as IT operations, security, and business analytics.

Add the Splunk repository, update, and install Splunk Connect for Kubernetes using dummy values.
```bash
helm repo add --force-update splunk-otel-collector-chart https://signalfx.github.io/splunk-otel-collector-chart
```
```bash
helm repo update
helm upgrade --install my-splunk-otel-collector \
  --set splunkPlatform.endpoint=https://127.0.0.1:8088/services/collector \
  --set splunkPlatform.token=xxxxxx \
  --set splunkPlatform.metricsIndex=k8s-metrics \
  --set splunkPlatform.index=main \
  --set splunkObservability.realm=us0 \
  --set splunkObservability.accessToken=xxxxxx \
  --set clusterName=my-cluster \
  splunk-otel-collector-chart/splunk-otel-collector
```

### Example Services – Client & Delivery

Deploy sample services to simulate inter-service communication. Each service is set with a unique name
and an environment variable (`APP_NAME`) that identifies it.

#### Build image

First, we need to build the image locally. For this, we'll use
[**docker**](https://docs.docker.com/reference/cli/docker/) if your container engine is **moby**, or
[**nerdctl**](https://github.com/containerd/nerdctl/blob/main/docs/command-reference.md) if your container
engine is **containerd**. If you are using containerd, you can change the container engine in Rancher
Desktop or just **substitute nerdctl for docker** in the commands below. From your **k8loglab**
directory:
```bash
docker build -t app:latest -f app/Dockerfile app
```
This will build the image, and you should be able to see **model** in the Rancher Desktop UI under **Images**.
You should also see it listed with the following.
```bash
docker images
```

#### Install services

Now you can install the example services with the following commands. **Note:** These are using the same image,
we're just renaming the service with the installation.
```bash
helm upgrade --install client ./charts/service \
  --set name=client \
  --set env[0].name=APP_NAME \
  --set env[0].value=client
```
```bash
helm upgrade --install delivery ./charts/service \
  --set name=delivery \
  --set env[0].name=APP_NAME \
  --set env[0].value=delivery
```

---

## Post-Installation: Accessing Grafana

After deploying Grafana, retrieve the credentials and set up port forwarding using the provided
`start-grafana.sh` script found in the repository’s source. To ensure the Grafana admin password is exported in
your current shell session, **source** the script:
```bash
source start-grafana.sh
```
This script:
- Retrieves the Grafana pod name.
- Extracts the Grafana admin password from the Kubernetes secret.
- Exports the `GRAFANA_ADMIN_PASSWORD` environment variable.
- Sets up port forwarding from the Grafana pod to [http://localhost:3000](http://localhost:3000).
- Sets up port forwarding from the loki pod to `http://loki-gateway.default.svc.cluster.local`. **Note:** This is
an in-cluster port forward, so you need to use this gateway to connect from grafana.

To log in:
- [**http://localhost:3000**](http://localhost:3000) - browse to this url in your browser
- **Username:** admin
- **Password:** The value stored in `GRAFANA_ADMIN_PASSWORD` (and echoed to the terminal).

**Persistence Warning:**
The deployed Grafana instance has persistence disabled. Any changes will be lost if the Grafana pod is terminated.
Consider enabling persistence via a Persistent Volume Claim (PVC) in the Helm chart's configuration for production
use.

### Add a loki data source.
Once you've run start-grafana.sh and logged into the browser site, from Grafana -> Connections -> Data Sources, select **Add data source**. Select Loki and enter the following settings:
- **URL:** http://loki-gateway.default.svc.cluster.local
- **HTTP headers**: Expand HTTP Headers and select "Add header"
    - **Header:** X-Scope-OrgID
    - **Value:** foo

Click "Save & Test" and you should see "Data source successfully connected." If not, check the above settings.

### Add a query
Select Grafana -> Explore. Set the data source to Loki (the default).
For the query, update the Label filters:
- **Label:** container
- **Value:** client
Select the Refresh symbol (top right) and you should see your logs. Select Live to see them as they come in.
---

## Troubleshooting

### Helm

After installing a release from a Helm chart, use the following.
```bash
helm list
```
You should see your release deployed. If the STATUS is failed, you can view the details with the
following.
```bash
helm get all <release-name>
```
If it is still unclear, you can run the installation with following additional arguments.
```bash
--debug --dry-run
```

### kubectl

If the Helm chart deployed successfully, the next step is to check the pod STATUS.
```bash
kubectl get pods
```
If any pod STATUS is not in Completed or Running, you can view the pod logs with the following.
```bash
kubectl describe pod <pod-name>
```
**Note:** The pod name will be something like `<replica set name>-<pod template hash>-<unique suffix>`,
**client-7c748796ff-n65ng** for example. There are other formats like StatefulSets and DaemonSets, that only
have a unique suffix, and no pod template hash, **loki-0** and **loki-promtail-6zk8s** for example.

---
