# Run Guide

## Prerequisites
- GCP Project with billing enabled
- `gcloud` CLI installed
- `terraform` >= 1.5.0
- `kubectl` configured
- `helm` >= 3.0
- Docker installed
- GitHub repository with Actions enabled

## 0. GCP Setup

### Create GCP Service Account
```bash
# Set variables
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"

# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account" \
  --project=$PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/container.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/artifactregistry.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:github-actions@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/iam.workloadIdentityUser
```

### Setup Workload Identity Federation
```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-pool" \
  --project=$PROJECT_ID \
  --location=global \
  --display-name="GitHub Actions Pool"

# Get the workload identity pool resource name
WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe "github-pool" \
  --project=$PROJECT_ID \
  --location=global \
  --format='value(name)')

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,assertion.aud=assertion.aud" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get the provider resource name
PROVIDER=$(gcloud iam workload-identity-pools providers describe "github-provider" \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool="github-pool" \
  --format='value(name)')

# Create Service Account for Workload Identity
gcloud iam service-accounts create openclaw-gke \
  --project=$PROJECT_ID

# Create Workload Identity binding
gcloud iam service-accounts add-iam-policy-binding "openclaw-gke@$PROJECT_ID.iam.gserviceaccount.com" \
  --project=$PROJECT_ID \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/$WORKLOAD_IDENTITY_POOL_ID/attribute.aud/aud1"
```

## 1. Configure GitHub Secrets

Add these secrets to your GitHub repository:
- `GCP_PROJECT`: Your GCP Project ID
- `GCP_SERVICE_ACCOUNT`: openclaw-gke@PROJECT_ID.iam.gserviceaccount.com
- `WIF_PROVIDER`: The provider resource name from above
- `GKE_CLUSTER_NAME`: openclaw-gke
- `GCP_REGION`: us-central1

## 2. Configure Terraform Variables

Create `terraform/terraform.tfvars`:
```hcl
project_id  = "your-gcp-project-id"
region      = "us-central1"
cluster_name = "openclaw-gke"
```

## 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

## 4. Build and Push Image (Manual or via GitHub Actions)

### Manual Build:
```bash
docker build -t us-central1-docker.pkg.dev/PROJECT_ID/openclaw/openclaw:latest .
docker push us-central1-docker.pkg.dev/PROJECT_ID/openclaw/openclaw:latest
```

### Automatic: Push to main branch (triggers GitHub Actions)

## 5. Deploy Application with Helm

```bash
# Get GKE credentials
gcloud container clusters get-credentials openclaw-gke --region us-central1

# Update values with your project ID
sed -i 's/YOUR_PROJECT_ID/YOUR_ACTUAL_PROJECT_ID/g' helm/openclaw/values.yaml

# Deploy
helm upgrade --install openclaw ./helm/openclaw \
  -n openclaw --create-namespace \
  --set image.tag=latest \
  --set gcpProject=your-gcp-project-id
```

## 6. Verify Deployment

```bash
# Check pods
kubectl get pods -n openclaw

# Check services
kubectl get svc -n openclaw

# Check ingress
kubectl get ingress -n openclaw

# Check HPA
kubectl get hpa -n openclaw

# View logs
kubectl logs -n openclaw -l app=openclaw -f
```

## 7. Access the Application

```bash
# Get external IP
kubectl get ingress -n openclaw
```

## 8. Teardown

```bash
# Uninstall Helm chart
helm uninstall openclaw -n openclaw

# Destroy infrastructure
cd terraform
terraform destroy
```

## Troubleshooting

### Image Pull Errors
```bash
# Ensure image pull secret exists
kubectl get secret artifact-registry-secret -n openclaw

# Recreate if needed
gcloud auth configure-docker us-central1-docker.pkg.dev
kubectl create secret docker-registry artifact-registry-secret \
  --docker-server=us-central1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat ~/.config/gcloud/application_default_credentials.json)" \
  -n openclaw
```

### GKE Cluster Access Issues
```bash
# Refresh credentials
gcloud container clusters get-credentials openclaw-gke --region us-central1

# Verify kubectl access
kubectl cluster-info
```

### Helm Deployment Issues
```bash
# Check Helm release status
helm status openclaw -n openclaw

# Rollback if needed
helm rollback openclaw -n openclaw

# Check values
helm get values openclaw -n openclaw
```
