# infrastructure/ — Terraform (GCP)

Infraestrutura como código para o data product `music-stream-rawdp`.
Provisiona recursos **reais** em GCP. Todos os identificadores são placeholders
(`REPLACE-ME-*`) — ver [../SETUP.md](../SETUP.md) para o passo a passo.

## Layout

```text
modules/
  project_factory/      # cria projeto GCP + ativa APIs
  service_account/      # service account + role bindings
  workload_identity/    # WIF (GitHub OIDC -> GCP, sem chaves)
  secret_manager/       # secrets (credenciais MongoDB)
  bigquery_dataset/     # dataset BigQuery
  bigquery_table/       # tabela BigQuery (partição opcional)
  storage/              # bucket GCS
  cloud_run_job/        # Artifact Registry + Cloud Run Job (dbt)
projects/
  bootstrap/            # cria projeto, SAs, IAM, WIF, state bucket, secrets
  resources/            # datasets, tabelas, storage, cloud run (backend GCS)
```

## Ordem de execução

1. **bootstrap** (backend local, uma vez por ambiente) — cria tudo o que é
   pré-requisito, incluindo o bucket de estado remoto.
2. **resources** (backend GCS) — cria os recursos do data product.

```bash
# 1) bootstrap
cd infrastructure/projects/bootstrap
terraform init
terraform apply -var-file=env_dev.tfvars

# 2) resources
cd ../resources
terraform init -backend-config="bucket=<project_id>-terraform-state"
terraform apply -var-file=env_dev.tfvars
```

Para produção, usar `env_prd.tfvars`. Em CI, os workflows `terraform-plan` e
`terraform-apply` fazem isto via Workload Identity Federation.
