variable "project_id" {
  description = "Project id where the repository is created"
  type        = string
}

variable "region" {
  description = "Region/location for the repository"
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

variable "repository_id" {
  description = "Artifact Registry repository id"
  type        = string
}
