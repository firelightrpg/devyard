# k8loglab: A Local Kubernetes Playground for Logging

k8loglab is designed as a lightweight environment to experiment with and manage your logging stack.
This guide describes setting up k8loglab on macOS using Homebrew and Rancher Desktop.

---

## Table of Contents

- [Overview](#overview)
- [Step 1: Install Rancher Desktop and cluster tools](#step-1-install-rancher-desktop-and-cluster-tools)
- [Step 2: Configure Your Logging Stack](#step-2-configure-your-logging-stack)
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

## Step 1: Install Rancher Desktop and cluster tools

### **Verify Homebrew:**

```bash
brew config | grep "Rosetta 2"
```

If the output shows `Rosetta 2: true` on an Apple Silicon machine, add the following to your shell
resource file (e.g., `.zshrc` or `.profile`):

```bash
eval $(/opt/homebrew/bin/brew shellenv)
```

Then source your resource file or restart your shell and ensure
`brew config | grep "Rosetta 2"` outputs `Rosetta 2: false`

### **Install Rancher Desktop:**

[**Rancher Desktop**](https://docs.rancherdesktop.io/) is a desktop application that simplifies running a
local Kubernetes cluster on your computer. It provides an intuitive GUI and CLI to manage
containerized applications and Kubernetes clusters easily on macOS, Windows, or Linux. Rancher
Desktop leverages container runtimes (like containerd or moby) and abstracts much of the complexity
of Kubernetes, making it a great tool for developers to build, test, and deploy applications locally
without the need for an external cloud-based Kubernetes environment.
```bash
brew install --cask rancher
```

### **Launch Rancher Desktop:**

Open Rancher Desktop from your Applications folder. Configure the following settings in Preferences:

- **Application:**
  - General: Enable Administrative Access.
  - Behavior:
    - Disable automatic start
    - Enable “Quit when closing application window.”
- **Virtual Machine:** Use the default settings with Emulation set to **QEMU**.
- **Container Engine:** Use moby (recommended for Docker).
  - **Note:** containerd will install the **nerdctl** CLI and moby will install **docker**
- **Kubernetes:**
  - Ensure it is **enabled**.
  - Set the version to stable (latest).
  - Verify the Kubernetes port is **6443**.

**Note:** Changing settings may require applying the changes, which can restart the cluster and
download images.

### Install kubernetes-cli:

The Kubernetes CLI ([**kubectl**](https://kubernetes.io/docs/reference/kubectl)) is a command-line tool for
interacting with Kubernetes clusters. It allows you to deploy, manage, and troubleshoot
applications running in Kubernetes by providing commands to create, update, delete, and inspect
various cluster resources. Kubectl is essential for both day-to-day operations and automating cluster
management tasks.
```bash
brew install kubernetes-cli
```

### Verify Your Kubernetes Cluster:
```bash
kubectl version
```
```bash
kubectl get nodes
```
```bash
kubectl get pods
```
**Note:** Initially, the default namespace will not have any resources.
```bash
kubectl get pods --all-namespaces
```
This should display the kube-system pods. The kube-system pods run the critical components and
services that manage and maintain your Kubernetes cluster. They include control plane components,
network proxies, DNS services, and other necessary add-ons that ensure the cluster functions
correctly.

**Note:** The status should be in Running or Completed. A running container will have a READY entry of
1/1. A Completed container will have a READY entry of 0/1. If more than one container is part of the
deployment, the entries will be 0/# and #/# respectively, where # is the number of containers.

### Install Helm

**[Helm](https://helm.sh/docs/)** is a package manager for Kubernetes that simplifies application deployment
and management. It uses charts—collections of YAML templates—to define, install, upgrade, and manage
Kubernetes resources in a consistent and repeatable way, much like apt or yum do for Linux packages.
It is a vital component to [**Infrastructure As Code**](https://aws.amazon.com/what-is/iac/).
```bash
brew install helm
```

### Clone Repository

Clone the **k8loglab** repository to get all the necessary charts and configuration files.
```bash
git clone git@github.com:Teladoc/k8loglab.git
cd k8loglab
```

---

## Step 2: Configure Your Logging Stack

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

[**Promtail**](https://grafana.com/docs/loki/latest/send-data/promtail/) is an agent that collects log
data from various sources (like container logs) and ships it to Loki. It enriches logs with metadata
(especially from Kubernetes) to facilitate powerful querying and log correlation in Loki.

Install the Loki stack (which includes Promtail). **Note:** We are loading loki.yaml to use the filesystem as a data source. A typical setup will load from a cloud source. 
```bash
helm repo update
helm upgrade --install loki grafana/loki -f loki.yaml
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

To log in:
- **Username:** admin
- **Password:** The value stored in `GRAFANA_ADMIN_PASSWORD`

**Persistence Warning:**
The deployed Grafana instance has persistence disabled. Any changes will be lost if the Grafana pod is terminated.
Consider enabling persistence via a Persistent Volume Claim (PVC) in the Helm chart's configuration for production
use.

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
