## ---------------------------------------------------------------------------
## Project variables
## ---------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "project_number" {
  description = "GCP project number"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "env" {
  description = "Environment short code (d/p)"
  type        = string
}

variable "domain" {
  description = "Data domain"
  type        = string
}

variable "subdomain" {
  description = "Data subdomain"
  type        = string
}

variable "dataproduct_name" {
  description = "Data product name"
  type        = string
}

variable "dataproduct_type" {
  description = "Data product type"
  type        = string
  validation {
    condition     = contains(["raw", "bus"], var.dataproduct_type)
    error_message = "The dataproduct_type must be one of ['raw', 'bus']."
  }
}

## ---------------------------------------------------------------------------
## Service Account variables (created by the bootstrap stack)
## ---------------------------------------------------------------------------
variable "sa_dbt" {
  description = "Service Account for dbt transformations"
  type        = string
}

variable "sa_orchestrator" {
  description = "Service Account for Astronomer orchestration"
  type        = string
}

variable "impersonate_service_account" {
  description = "Optional SA email for the provider to impersonate. Null to authenticate directly (e.g. via WIF)."
  type        = string
  default     = null
}
