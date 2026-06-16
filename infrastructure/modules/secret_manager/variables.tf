variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "dataproduct_name" {
  type = string
}

variable "secret_id" {
  description = "Secret id (name)"
  type        = string
}

variable "accessor_members" {
  description = "IAM members granted secretAccessor (e.g. serviceAccount:...)"
  type        = list(string)
  default     = []
}
