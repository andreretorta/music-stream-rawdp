variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "env" {
  description = "Environment short code (d/p)"
  type        = string
}

variable "dataproduct_name" {
  description = "Data product name"
  type        = string
}

variable "dataset_name" {
  description = "BigQuery dataset id"
  type        = string
}

variable "dataset_description" {
  description = "BigQuery dataset description"
  type        = string
  default     = ""
}

variable "dataset_location" {
  description = "BigQuery dataset location"
  type        = string
}
