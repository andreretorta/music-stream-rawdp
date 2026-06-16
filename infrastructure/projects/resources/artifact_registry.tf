## ---------------------------------------------------------------------------
## Artifact Registry repository for the dbt runner image.
## The image is built & pushed by the `build-dbt-image` workflow (or locally)
## and must exist before the Cloud Run job below can be created.
## ---------------------------------------------------------------------------
module "artifact_registry_dbt" {
  source = "../../modules/artifact_registry"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  repository_id = "ar-${var.dataproduct_name}-${var.env}"
}
