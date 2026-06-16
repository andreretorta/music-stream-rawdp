## ---------------------------------------------------------------------------
## Internal raw tables (landing zone for GCS-to-BigQuery loads)
## Schemas are kept in ./schemas/*.json
## ---------------------------------------------------------------------------
locals {
  internal_tables = {
    t_raw_genre  = "${path.module}/schemas/t_raw_genre.json"
    t_raw_artist = "${path.module}/schemas/t_raw_artist.json"
    t_raw_track  = "${path.module}/schemas/t_raw_track.json"
    t_raw_stream = "${path.module}/schemas/t_raw_stream.json"
  }
}

module "internal_tables" {
  source   = "../../modules/bigquery_table"
  for_each = local.internal_tables

  project_id       = var.project_id
  env              = var.env
  dataproduct_name = var.dataproduct_name

  dataset_id          = module.dataset_internal.dataset_id
  table_name          = each.key
  table_description   = "Raw landing table ${each.key}"
  schema_json         = file(each.value)
  partition_field     = "airflow_ds"
  deletion_protection = false

  depends_on = [module.dataset_internal]
}
