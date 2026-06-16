resource "google_bigquery_dataset" "this" {
  project       = var.project_id
  dataset_id    = var.dataset_name
  friendly_name = var.dataset_name
  description   = var.dataset_description
  location      = var.dataset_location

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }

  delete_contents_on_destroy = false
}

# Dataset-level IAM bindings (e.g. grant the orchestrator/dbt service accounts
# data editor/viewer access). Flattened from a map of role => [members].
locals {
  dataset_iam_pairs = flatten([
    for role, members in var.iam_members : [
      for m in members : { role = role, member = m }
    ]
  ])
}

resource "google_bigquery_dataset_iam_member" "members" {
  for_each = {
    for p in local.dataset_iam_pairs : "${p.role}|${p.member}" => p
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.this.dataset_id
  role       = each.value.role
  member     = each.value.member
}
