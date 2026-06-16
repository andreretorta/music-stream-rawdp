## ---------------------------------------------------------------------------
## Secret Manager secret (e.g. MongoDB user / password).
##
## The secret *value* is intentionally NOT managed by Terraform to avoid
## storing credentials in state. Create versions out-of-band, e.g.:
##   echo -n "my-password" | gcloud secrets versions add MONGO_PW --data-file=-
## ---------------------------------------------------------------------------
resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    auto {}
  }

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }
}

# Grant read access to the accessor service accounts.
resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each = toset(var.accessor_members)

  project   = var.project_id
  secret_id = google_secret_manager_secret.this.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}
