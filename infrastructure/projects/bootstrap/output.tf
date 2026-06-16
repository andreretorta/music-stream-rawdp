output "project_id" {
  description = "Created project id"
  value       = module.project.project_id
}

output "project_number" {
  description = "Created project number"
  value       = module.project.project_number
}

output "tf_state_bucket" {
  description = "Terraform state bucket for the resources stack"
  value       = google_storage_bucket.tf_state.name
}

output "wif_provider" {
  description = "Use as 'workload_identity_provider' in GitHub Actions auth step"
  value       = module.wif.provider_name
}

output "sa_deployer_email" {
  description = "Service account GitHub Actions impersonates"
  value       = module.sa_deployer.email
}

output "service_accounts" {
  description = "All created service account emails"
  value = {
    deployer     = module.sa_deployer.email
    orchestrator = module.sa_orchestrator.email
    dbt          = module.sa_dbt.email
    ingestion    = module.sa_ingestion.email
  }
}
