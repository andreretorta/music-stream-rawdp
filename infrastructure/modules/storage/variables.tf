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

variable "bucket_name" {
  type = string
}

variable "storage_class" {
  type    = string
  default = "STANDARD"
}

variable "versioning" {
  type    = bool
  default = false
}

variable "age_days_to_delete" {
  description = "Lifecycle: delete objects older than N days. Null to disable."
  type        = number
  default     = null
}
