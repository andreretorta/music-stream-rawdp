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
