## ---------------------------------------------------------------------------
## Bootstrap — Terraform configuration
##
## This stack creates the GCP project, enables APIs, provisions service
## accounts + IAM, configures Workload Identity Federation for GitHub Actions,
## creates the Terraform state bucket and the Secret Manager secrets.
##
## It uses a LOCAL backend on purpose (chicken-and-egg: it creates the very
## bucket used as remote backend by the `resources` stack). Run it once per
## environment with your own admin credentials.
## ---------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.49.0"
    }
  }
}

provider "google" {
  region = var.region
}
