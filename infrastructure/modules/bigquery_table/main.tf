resource "google_bigquery_table" "this" {
  project             = var.project_id
  dataset_id          = var.dataset_id
  table_id            = var.table_name
  description         = var.table_description
  deletion_protection = var.deletion_protection

  schema = var.schema_json

  dynamic "time_partitioning" {
    for_each = var.partition_field == null ? [] : [1]
    content {
      type  = "DAY"
      field = var.partition_field
    }
  }

  labels = {
    dataproduct = var.dataproduct_name
    env         = var.env
  }
}
