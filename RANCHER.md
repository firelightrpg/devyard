# Rancher Desktop

## **Verify Homebrew:**

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

## **Install Rancher Desktop:**

[**Rancher Desktop**](https://docs.rancherdesktop.io/) is a desktop application that simplifies running a
local Kubernetes cluster on your computer. It provides an intuitive GUI and CLI to manage
containerized applications and Kubernetes clusters easily on macOS, Windows, or Linux. Rancher
Desktop leverages container runtimes (like containerd or moby) and abstracts much of the complexity
of Kubernetes, making it a great tool for developers to build, test, and deploy applications locally
without the need for an external cloud-based Kubernetes environment.
```bash
brew install --cask rancher
```

## **Launch Rancher Desktop:**

Open Rancher Desktop from your Applications folder or Launchpad. Select Open if prompted with
_“Rancher Desktop” is an app downloaded from the Internet. Are you sure you want to open it?_.

**Note:** You may be prompted for Administrative Access. You can check the box to disable administrator
access if you don't have admin privileges.

Configure the following settings in Preferences:

- **Application:**
  - **General**: Administrative Access. You can run rancher with, or without administrator access.
  - **Behavior**:
    Rancher Desktop uses a significant amount of resources, so you may want to manually control startup.
    - Disable automatic start
    - Enable “Quit when closing application window.”
- **Virtual Machine:** Use the default settings with **Emulation** set to **QEMU**.
- **Container Engine:** Use **dockerd(moby)** (recommended for Docker).
  - **Note:** **containerd** works with **nerdctl** CLI and moby works with **docker**
- **Kubernetes:**
  - Ensure it is **enabled**.
  - Set the version to stable (latest).
  - Verify the Kubernetes port is **6443**.

**Note:** Changing settings may require applying the changes, which can restart the cluster and
download images.

## Rancher Desktop installs the following tools:
**Note:** You may need to open a new terminal for the tools to be available.
- [**Helm**](https://helm.sh/) is a package manager for Kubernetes that simplifies application deployment
and management. It uses charts—collections of YAML templates—to define, install, upgrade, and manage
Kubernetes resources in a consistent and repeatable way, much like apt or yum do for Linux packages.
It is a vital component to [**Infrastructure As Code**](https://aws.amazon.com/what-is/iac/).
- [**kubectl**](https://kubernetes.io/docs/reference/kubectl/overview/) is a command-line tool for
interacting with Kubernetes clusters. It allows you to deploy, manage, and troubleshoot
applications running in Kubernetes by providing commands to create, update, delete, and inspect
various cluster resources. Kubectl is essential for both day-to-day operations and automating cluster
management tasks.
- [**nerdctl**](https://github.com/containerd/nerdctl) is a Docker‑compatible command‑line interface for
containerd that lets you manage containers, images, volumes, and pods without needing the Docker Engine.
It implements most Docker CLI commands (build, pull, run, compose, etc.) on top of containerd.
- [**docker** (Moby)](https://github.com/moby/moby) is the standard CLI client for the Docker Engine API—it
lets you build, pull, run, and manage container images, containers, networks, and volumes on a Docker
daemon.
- [**Docker Compose**](https://docs.docker.com/compose/) is the Docker CLI plugin that reads a Compose
YAML file to define and orchestrate multi‑container applications—letting you bring up, tear down, and
manage an entire stack (services, networks, volumes) with simple commands like docker compose up and docker
compose down.

For this lab, we'll primarily use **helm**, **kubectl** and **docker**.


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
