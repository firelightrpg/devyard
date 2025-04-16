"""
probe the app services from a local environment
"""

from kubernetes import client, config

config.load_kube_config()
v1 = client.CoreV1Api()

services = v1.list_namespaced_service(namespace="default")
for svc in services.items:
    chart = svc.metadata.labels.get("helm.sh/chart", "")
    if chart.startswith("app-"):
        print(svc.metadata.name)
