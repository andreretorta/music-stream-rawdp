## ---------------------------------------------------------------------------
## 1. Create the project + enable APIs
## ---------------------------------------------------------------------------
module "project" {
  source = "../../modules/project_factory"

  project_id       = var.project_id
  billing_account  = var.billing_account
  org_id           = var.org_id
  folder_id        = var.folder_id
  env              = var.env
  dataproduct_name = var.dataproduct_name
}

## ---------------------------------------------------------------------------
## 2. Service accounts
## ---------------------------------------------------------------------------

# Terraform / CI deployer (used by GitHub Actions via WIF).
module "sa_deployer" {
  source = "../../modules/service_account"

  project_id   = module.project.project_id
  account_id   = "sa-terraform-deployer"
  display_name = "Terraform / CI deployer"
  description  = "Provisions resources and is impersonated by GitHub Actions"
  roles = [
    "roles/editor",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/secretmanager.admin",
  ]
}

# Airflow / Astronomer orchestrator.
module "sa_orchestrator" {
  source = "../../modules/service_account"

  project_id   = module.project.project_id
  account_id   = "sa-astronomer"
  display_name = "Astronomer orchestrator"
  description  = "Runs DAGs, triggers Cloud Run jobs"
  roles = [
    "roles/run.invoker",
    "roles/run.developer",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
    "roles/iam.serviceAccountTokenCreator",
  ]
}

# dbt transformation runner (Cloud Run job identity).
module "sa_dbt" {
  source = "../../modules/service_account"

  project_id   = module.project.project_id
  account_id   = "sa-r-dataconsumption"
  display_name = "dbt transformation runner"
  description  = "Executes dbt against BigQuery"
  roles = [
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
  ]
}

# MongoDB -> GCS ingestion identity.
module "sa_ingestion" {
  source = "../../modules/service_account"

  project_id   = module.project.project_id
  account_id   = "sa-ingestion"
  display_name = "MongoDB to GCS ingestion"
  description  = "Reads source MongoDB and lands data in GCS"
  roles = [
    "roles/storage.objectAdmin",
    "roles/secretmanager.secretAccessor",
  ]
}

## ---------------------------------------------------------------------------
## 3. Workload Identity Federation (GitHub Actions -> GCP, keyless)
## ---------------------------------------------------------------------------
module "wif" {
  source = "../../modules/workload_identity"

  project_id        = module.project.project_id
  github_repository = var.github_repository
  deployer_service_accounts = [
    module.sa_deployer.email,
  ]
}

## ---------------------------------------------------------------------------
## 4. Terraform state bucket (remote backend for the `resources` stack)
## ---------------------------------------------------------------------------
resource "google_storage_bucket" "tf_state" {
  project                     = module.project.project_id
  name                        = "${var.project_id}-terraform-state"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }
}

## ---------------------------------------------------------------------------
## 5. Secret Manager — MongoDB credentials (values added out-of-band)
## ---------------------------------------------------------------------------
module "secret_mongo_user" {
  source = "../../modules/secret_manager"

  project_id       = module.project.project_id
  env              = var.env
  dataproduct_name = var.dataproduct_name
  secret_id        = "MONGO_USER"
  accessor_members = [
    module.sa_ingestion.member,
  ]
}

module "secret_mongo_pw" {
  source = "../../modules/secret_manager"

  project_id       = module.project.project_id
  env              = var.env
  dataproduct_name = var.dataproduct_name
  secret_id        = "MONGO_PW"
  accessor_members = [
    module.sa_ingestion.member,
  ]
}
