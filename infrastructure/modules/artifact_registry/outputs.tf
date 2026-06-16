output "repository_id" {
  description = "The repository id"
  value       = google_artifact_registry_repository.this.repository_id
}

output "name" {
  description = "The full resource name of the repository"
  value       = google_artifact_registry_repository.this.name
}

output "registry_url" {
  description = "Base URL to push/pull images (region-docker.pkg.dev/project/repo)"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}
