variable "project_id" {
  description = "Project where the service account is created"
  type        = string
}

variable "account_id" {
  description = "Service account id (the part before @)"
  type        = string
}

variable "display_name" {
  description = "Human-friendly name"
  type        = string
  default     = ""
}

variable "description" {
  description = "Service account description"
  type        = string
  default     = ""
}

variable "roles" {
  description = "Project-level IAM roles to grant to the service account"
  type        = list(string)
  default     = []
}
