## ---------------------------------------------------------------------------
## BigQuery datasets (medallion layers + monitoring)
## ---------------------------------------------------------------------------
module "dataset_internal" {
  source = "../../modules/bigquery_dataset"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  dataset_name        = "internal"
  dataset_description = "Raw landing tables loaded from GCS"
  dataset_location    = var.region

  iam_members = {
    "roles/bigquery.dataEditor" = ["serviceAccount:${var.sa_orchestrator}"]
    "roles/bigquery.dataViewer" = ["serviceAccount:${var.sa_dbt}"]
  }
}

module "dataset_master" {
  source = "../../modules/bigquery_dataset"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  dataset_name        = "master"
  dataset_description = "Cleaned/typed master tables"
  dataset_location    = var.region

  iam_members = {
    # dataOwner (not just dataEditor) so dbt can authorise the output_clear
    # views to read master via `grant_access_to` (needs datasets.update).
    "roles/bigquery.dataOwner" = ["serviceAccount:${var.sa_dbt}"]
  }
}

module "dataset_output_clear" {
  source = "../../modules/bigquery_dataset"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  dataset_name        = "output_clear"
  dataset_description = "Consumer-facing views"
  dataset_location    = var.region

  iam_members = {
    "roles/bigquery.dataEditor" = ["serviceAccount:${var.sa_dbt}"]
  }

  depends_on = [module.dataset_master]
}

module "dataset_monitoring" {
  source = "../../modules/bigquery_dataset"

  project_id       = var.project_id
  region           = var.region
  env              = var.env
  dataproduct_name = var.dataproduct_name

  dataset_name        = "monitoring"
  dataset_description = "Freshness / data quality metrics"
  dataset_location    = var.region

  iam_members = {
    "roles/bigquery.dataEditor" = ["serviceAccount:${var.sa_dbt}"]
  }
}
