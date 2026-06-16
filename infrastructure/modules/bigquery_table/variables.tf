variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "dataproduct_name" {
  type = string
}

variable "dataset_id" {
  type = string
}

variable "table_name" {
  type = string
}

variable "table_description" {
  type    = string
  default = ""
}

variable "schema_json" {
  description = "JSON-encoded BigQuery schema"
  type        = string
}

variable "partition_field" {
  description = "Field to partition by (DAY). Null to disable partitioning."
  type        = string
  default     = null
}

variable "deletion_protection" {
  type    = bool
  default = true
}
