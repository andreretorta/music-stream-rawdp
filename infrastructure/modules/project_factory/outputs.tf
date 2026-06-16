output "project_id" {
  description = "The created project id"
  value       = google_project.this.project_id
}

output "project_number" {
  description = "The created project number"
  value       = google_project.this.number
}

output "enabled_apis" {
  description = "APIs enabled on the project"
  value       = [for s in google_project_service.this : s.service]
}
