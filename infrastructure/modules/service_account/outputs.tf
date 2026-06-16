output "email" {
  description = "The service account email"
  value       = google_service_account.this.email
}

output "name" {
  description = "The fully-qualified service account name"
  value       = google_service_account.this.name
}

output "member" {
  description = "IAM member string (serviceAccount:<email>)"
  value       = "serviceAccount:${google_service_account.this.email}"
}
