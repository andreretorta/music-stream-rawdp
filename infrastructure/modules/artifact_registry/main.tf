## ---------------------------------------------------------------------------
## Artifact Registry repository (Docker) for the dbt runner image.
## ---------------------------------------------------------------------------
resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Docker images for ${var.dataproduct_name} (${var.env})"

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
    managed_by  = "terraform"
  }
}
