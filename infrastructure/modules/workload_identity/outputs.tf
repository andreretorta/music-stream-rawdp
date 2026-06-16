output "pool_name" {
  description = "Full resource name of the WIF pool"
  value       = google_iam_workload_identity_pool.github.name
}

output "provider_name" {
  description = "Full resource name of the WIF provider (use as workload_identity_provider in GitHub Actions)"
  value       = google_iam_workload_identity_pool_provider.github.name
}
