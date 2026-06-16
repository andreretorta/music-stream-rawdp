resource "google_cloud_run_v2_job" "this" {
  project             = var.project_id
  name                = var.job_name
  location            = var.region
  deletion_protection = false

  template {
    template {
      service_account = var.job_sa
      timeout         = "3600s"
      max_retries     = 1

      containers {
        name  = "dbt-runner"
        image = var.image

        resources {
          limits = {
            cpu    = "2"
            memory = "2Gi"
          }
        }

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }
}

# Allow the orchestrator SA to invoke / execute the job.
resource "google_cloud_run_v2_job_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.this.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.orchestrator_sa}"
}
