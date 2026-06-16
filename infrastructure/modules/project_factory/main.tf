## ---------------------------------------------------------------------------
## Project factory: creates a GCP project, links billing and enables APIs.
## ---------------------------------------------------------------------------
resource "google_project" "this" {
  name            = var.project_id
  project_id      = var.project_id
  billing_account = var.billing_account

  # Exactly one of org_id / folder_id should be set.
  org_id    = var.folder_id == null ? var.org_id : null
  folder_id = var.folder_id

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
    managed_by  = "terraform"
  }
}

resource "google_project_service" "this" {
  for_each = toset(var.activate_apis)

  project = google_project.this.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}
