variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "dataproduct_name" {
  type = string
}

variable "job_name" {
  type = string
}

variable "image" {
  description = "Container image URI for the dbt job"
  type        = string
}

variable "job_sa" {
  description = "Service account used to run the job"
  type        = string
}

variable "orchestrator_sa" {
  description = "Service account allowed to execute the job (Airflow/Astronomer)"
  type        = string
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}
