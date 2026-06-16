## ---------------------------------------------------------------------------
## Terraform configuration
## ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  # GCS backend. The bucket is created by the `bootstrap` stack and is named
  # "<project_id>-terraform-state". It is left partial on purpose: pass it at
  # init time, e.g.:
  #   terraform init -backend-config="bucket=<project_id>-terraform-state"
  backend "gcs" {
    prefix = "resources"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.49.0"
    }
  }
}

## ---------------------------------------------------------------------------
## Provider configuration
## ---------------------------------------------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region

  # When CI authenticates as the deployer SA via WIF it can act directly.
  # Set `impersonate_service_account` if you prefer to impersonate another SA.
  impersonate_service_account = var.impersonate_service_account
}
