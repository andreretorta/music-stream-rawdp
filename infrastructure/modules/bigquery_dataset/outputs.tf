output "dataset_id" {
  description = "The created BigQuery dataset id"
  value       = google_bigquery_dataset.this.dataset_id
}

output "self_link" {
  description = "Self link of the dataset"
  value       = google_bigquery_dataset.this.self_link
}
