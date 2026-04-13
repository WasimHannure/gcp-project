Overview

This repository provisions infrastructure on Google Cloud Platform using Terraform and deploys the OpenClaw application to Google Kubernetes Engine using Helm.

The deployment includes:

VPC and subnet creation
GKE cluster
Artifact Registry repository
Workload Identity
Kubernetes Deployment, Service, Ingress, HPA, and NetworkPolicy
GitHub Actions CI/CD pipeline

Prerequisites

Before starting, make sure the following are installed:

Google Cloud SDK (gcloud)
Terraform >= 1.5
Docker
kubectl
Helm 3
Git

Enable APIs

gcloud services enable compute.googleapis.com \
container.googleapis.com \
artifactregistry.googleapis.com \
iam.googleapis.com

Configure Github Secrets
WIF_PROVIDER
GCP_SERVICE_ACCOUNT


Deploy Infrastructure from GitHub Actions
Build and Push Docker Image
Deploy with Helm

Verify
- name: Verify Deployment
  run: |
    kubectl get pods -n openclaw
    kubectl get ingress -n openclaw