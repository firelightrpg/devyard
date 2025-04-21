"""
Service app template with inter-service traffic simulation.
"""

import logging
import os
import random
import sys
import threading
import time

import requests
from fastapi import FastAPI
from kubernetes import client, config
from kubernetes.client.exceptions import ApiException
from kubernetes.config.config_exception import ConfigException
from requests.exceptions import HTTPError

app = FastAPI()
app_name = os.environ["APP_NAME"]


handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter(
    "%(asctime)s [%(name)s] %(levelname)s: %(message)s", "%Y-%m-%d %H:%M:%S"
)
handler.setFormatter(formatter)

root = logging.getLogger()
root.setLevel(logging.INFO)
root.handlers = [handler]  # Replace any existing handlers
logger = logging.getLogger(app_name)


def init_kube_client(retries=5, delay=2):
    """
    Attempt to load in-cluster Kubernetes config, with retries.
    """
    for attempt in range(retries):
        try:
            config.load_incluster_config()
            return client.CoreV1Api()
        except ConfigException:
            if attempt < retries - 1:
                logger.warning(f"Kube config not found. Retrying in {delay} sec...")
                time.sleep(delay)
            else:
                raise


core_v1 = init_kube_client()


def get_dynamic_peers():
    """
    Return a list of peer service names matching the Helm chart label `app-*`.
    """
    try:
        services = core_v1.list_namespaced_service(namespace="default")
        discovered = []

        for svc in services.items:
            labels = svc.metadata.labels or {}
            chart_label = labels.get("helm.sh/chart", "")
            name = svc.metadata.name

            if chart_label.startswith("app-") and name != app_name:
                discovered.append(name)

        return discovered
    except (ApiException, HTTPError):
        logger.error("Failed to discover peers via Kubernetes")
        return []


def cpu_work():
    """
    Simulate CPU-intensive work.
    """
    x = 0
    for _ in range(10**6):
        x += random.randint(1, 10)
    return x


@app.get("/health")
def health():
    """
    Health check endpoint.
    """
    return {"status": "ok", "app": app_name}


@app.get("/do_work")
def do_work():
    """
    Trigger work.
    """
    logger.info("Work started")
    cpu_work()
    logger.info("Work complete")
    return {"status": "done", "app": app_name}


@app.get("/threaded_work")
def threaded_work():
    """
    Run some work in the background.
    """

    def background_job():
        logger.info("Threaded work started")
        time.sleep(random.uniform(1, 3))
        logger.info("Threaded work complete")

    thread = threading.Thread(target=background_job)
    thread.start()
    return {"status": "threaded job started", "app": app_name}


def simulate_inter_service_traffic():
    """
    Periodically discovers services with helm.sh/chart=app-* and communicates with them.
    """
    while True:
        peers = get_dynamic_peers()
        if peers:
            peer = random.choice(peers)
            try:
                url_health = f"http://{peer}/health"
                logger.info(f"Calling health check on peer: {peer} {url_health}")
                response = requests.get(url_health, timeout=5)
                logger.info(f"Peer {peer} health: {response.json()}")

                if random.choice([True, False]):
                    url_do_work = f"http://{peer}/do_work"
                    logger.info(f"Triggering work on peer: {peer}")
                    work_response = requests.get(url_do_work, timeout=5)
                    logger.info(f"Peer {peer} work response: {work_response.json()}")
            except requests.RequestException:
                logger.error("Hit error with request")

        time.sleep(random.uniform(5, 15))


# Start the background thread for inter-service traffic simulation.
threading.Thread(target=simulate_inter_service_traffic, daemon=True).start()
