variable "project_id" {
  description = "Project hosting the WIF pool"
  type        = string
}

variable "pool_id" {
  description = "Workload identity pool id"
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload identity pool provider id"
  type        = string
  default     = "github-provider"
}

variable "github_repository" {
  description = "GitHub repository in 'owner/name' form allowed to authenticate"
  type        = string
}

variable "deployer_service_accounts" {
  description = "Service account emails the GitHub repo may impersonate"
  type        = list(string)
  default     = []
}
