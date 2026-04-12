output "kubernetes_cluster_name" {
  value       = google_container_cluster.gke.name
  description = "GKE Cluster name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.gke.endpoint
  sensitive   = true
  description = "GKE Cluster host"
}

output "region" {
  value       = var.region
  description = "GCP region"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "artifact_registry_repository" {
  value       = google_artifact_registry_repository.openclaw_repo.repository_id
  description = "Artifact Registry repository ID"
}
