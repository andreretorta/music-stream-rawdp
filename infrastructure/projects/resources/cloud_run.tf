## ---------------------------------------------------------------------------
## Cloud Run job running the dbt transformations
## ---------------------------------------------------------------------------
module "cloudrun_dbt" {
  source = "../../modules/cloud_run_job"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  job_name        = "gcr-${var.dataproduct_name}-${var.env}-${var.region}-dbt"
  image           = "${var.region}-docker.pkg.dev/${var.project_id}/ar-${var.dataproduct_name}-${var.env}/dbt:latest"
  job_sa          = var.sa_dbt
  orchestrator_sa = var.sa_orchestrator

  env_vars = {
    DBT_PROJECT = var.dataproduct_name
  }

  depends_on = [
    module.dataset_internal,
    module.dataset_master,
    module.dataset_output_clear,
    module.dataset_monitoring,
    module.code_bucket,
    module.artifact_registry_dbt,
  ]
}
