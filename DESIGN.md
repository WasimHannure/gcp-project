# Design Decisions

- GKE Autopilot-ready cluster created through Terraform.
- Artifact Registry stores container images.
- Helm chart separates deployment configuration from infrastructure.
- Workload Identity maps Kubernetes service account to GCP service account.
- Secrets should be retrieved from Secret Manager and mounted through CSI driver or Kubernetes Secret.
- HPA automatically scales between 2 and 5 pods based on CPU.
- NetworkPolicy only allows ingress traffic from the Ingress controller namespace.
- GitHub Actions pipeline builds and deploys on push to main.
