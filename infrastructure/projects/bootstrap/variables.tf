variable "project_id" {
  description = "GCP project id to create (must be globally unique)"
  type        = string
}

variable "billing_account" {
  description = "Billing account id (e.g. 0X0X0X-0X0X0X-0X0X0X)"
  type        = string
}

variable "org_id" {
  description = "Organization id (numeric). Used when folder_id is null."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Folder id (e.g. folders/123456). Takes precedence over org_id."
  type        = string
  default     = null
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

variable "dataproduct_name" {
  description = "Data product name"
  type        = string
  default     = "music-stream-rawdp"
}

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to deploy via WIF"
  type        = string
}
