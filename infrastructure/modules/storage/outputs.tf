output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.this
}

output "name" {
  value = google_storage_bucket.this.name
}
