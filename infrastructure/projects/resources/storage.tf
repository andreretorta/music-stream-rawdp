## ---------------------------------------------------------------------------
## Storage buckets
## ---------------------------------------------------------------------------
module "ingestion_bucket" {
  source = "../../modules/storage"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  bucket_name        = "${var.project_id}-ingestion"
  age_days_to_delete = 30
}

module "code_bucket" {
  source = "../../modules/storage"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  bucket_name = "gcs-${var.project_id}-cloud-run-docker"
  versioning  = true
}
