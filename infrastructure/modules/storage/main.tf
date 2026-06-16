resource "google_storage_bucket" "this" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.age_days_to_delete == null ? [] : [1]
    content {
      action {
        type = "Delete"
      }
      condition {
        age = var.age_days_to_delete
      }
    }
  }

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }
}
