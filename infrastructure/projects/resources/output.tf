output "ingestion_bucket" {
  description = "Name of the ingestion bucket"
  value       = module.ingestion_bucket.name
}

output "dbt_job_name" {
  description = "Cloud Run job name for dbt"
  value       = module.cloudrun_dbt.job_name
}

output "datasets" {
  description = "Created BigQuery datasets"
  value = [
    module.dataset_internal.dataset_id,
    module.dataset_master.dataset_id,
    module.dataset_output_clear.dataset_id,
    module.dataset_monitoring.dataset_id,
  ]
}
