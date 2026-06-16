variable "project_id" {
  description = "The project id to create (must be globally unique)"
  type        = string
}

variable "billing_account" {
  description = "Billing account id to associate (e.g. 0X0X0X-0X0X0X-0X0X0X)"
  type        = string
}

variable "org_id" {
  description = "Organization id. Used when folder_id is null."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder id (e.g. folders/123456). Takes precedence over org_id."
  type        = string
  default     = null
}

variable "env" {
  description = "Environment short code (d/p)"
  type        = string
}

variable "dataproduct_name" {
  description = "Data product name"
  type        = string
}

variable "activate_apis" {
  description = "List of Google APIs to enable on the project"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "sts.googleapis.com",
  ]
}
