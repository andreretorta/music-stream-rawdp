# SETUP — Provisionar em GCP (real)

Este guia leva-te de "repositório" até um **data product a correr em GCP real**,
com projetos, service accounts, IAM, Workload Identity Federation (CI sem chaves)
e Secret Manager. Substitui todos os valores `REPLACE-ME-*`.

> Todos os identificadores neste repositório são placeholders. Nada aqui aponta
> para um sistema real até o preencheres com os teus valores.

## 0. Pré-requisitos

- Conta GCP com **billing account** ativa e permissões para criar projetos
  (Project Creator na organização **ou** numa folder).
- [`gcloud` CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform >= 1.6](https://developer.hashicorp.com/terraform/downloads)
- Um repositório GitHub para este código (para o WIF).

Recolhe estes valores:

| Valor | Onde obter |
| ----- | ---------- |
| `billing_account` | `gcloud billing accounts list` |
| `org_id` ou `folder_id` | `gcloud organizations list` / `gcloud resource-manager folders list` |
| `github_repository` | `owner/nome-do-repo` |
| `project_id` (dev/prd) | escolhe IDs únicos globalmente |

## 1. Autenticar localmente

```powershell
gcloud auth login
gcloud auth application-default login
```

## 2. Bootstrap (cria projeto + SAs + WIF + state bucket + secrets)

A stack `bootstrap` usa backend **local** (cria o bucket que as outras stacks
usam como backend remoto). Corre uma vez por ambiente.

Edita [infrastructure/projects/bootstrap/env_dev.tfvars](infrastructure/projects/bootstrap/env_dev.tfvars)
(e `env_prd.tfvars`) e substitui os `REPLACE-ME-*`.

```powershell
cd infrastructure/projects/bootstrap

terraform init
terraform apply -var-file=env_dev.tfvars   # ambiente dev
terraform apply -var-file=env_prd.tfvars   # ambiente prd
```

Guarda os outputs (precisas deles a seguir):

```powershell
terraform output
# wif_provider      -> ex: projects/123.../workloadIdentityPools/github-pool/providers/github-provider
# sa_deployer_email -> sa-terraform-deployer@<project>.iam.gserviceaccount.com
# tf_state_bucket   -> <project>-terraform-state
```

## 3. Guardar as credenciais do MongoDB no Secret Manager

Os secrets `MONGO_USER` e `MONGO_PW` são criados vazios pela bootstrap. Adiciona
as versões com os valores reais (o Terraform nunca toca nos valores):

```powershell
echo -n "o-teu-utilizador" | gcloud secrets versions add MONGO_USER --data-file=- --project <project_id>
echo -n "a-tua-password"    | gcloud secrets versions add MONGO_PW   --data-file=- --project <project_id>
```

## 4. Configurar segredos no GitHub

Os workflows precisam destes **secrets** (e uma variável). Lista completa:

| Nome | Tipo | Valor | Usado por |
| ---- | ---- | ----- | --------- |
| `WIF_PROVIDER` | secret | output `wif_provider` da bootstrap | terraform-plan/apply, build-dbt-image |
| `DEPLOYER_SA` | secret | output `sa_deployer_email` | terraform-plan/apply, build-dbt-image |
| `GCP_PROJECT_DEV` | secret | project id dev | terraform-plan/apply, build-dbt-image |
| `GCP_PROJECT_PRD` | secret | project id prd | terraform-plan/apply, build-dbt-image |
| `ASTRO_API_TOKEN` | secret | token da Astronomer | deploy-astro |
| `ASTRO_DEPLOYMENT_ID_DEV` | secret | id do deployment Astro (dev) | deploy-astro |
| `ASTRO_DEPLOYMENT_ID_PRD` | secret | id do deployment Astro (prd) | deploy-astro |
| `GCP_REGION` | **variable** | região (default `europe-west1`) | build-dbt-image |

> Os secrets `ASTRO_*` só são necessários se usares a Astronomer. Sem eles, o
> workflow `deploy-astro` falha mas os de Terraform/imagem funcionam à mesma.

### Opção A — Script automático (recomendado)

Requer [`gh` CLI](https://cli.github.com/) autenticado (`gh auth login`) e a
bootstrap já aplicada (o script lê `WIF_PROVIDER`/`DEPLOYER_SA` dos outputs):

```powershell
./scripts/set_github_secrets.ps1 `
  -Repo "owner/music-stream-rawdp" `
  -ProjectDev "<project_id_dev>" `
  -ProjectPrd "<project_id_prd>" `
  -Region "europe-west1" `
  -AstroApiToken "<token>" `
  -AstroDeploymentIdDev "<dep-dev>" `
  -AstroDeploymentIdPrd "<dep-prd>"
```

Equivalente em bash: `scripts/set_github_secrets.sh --repo ... --project-dev ... --project-prd ...`.

### Opção B — Manual via `gh`

```powershell
$repo = "owner/music-stream-rawdp"
terraform -chdir=infrastructure/projects/bootstrap output -raw wif_provider     | gh secret set WIF_PROVIDER     --repo $repo --body -
terraform -chdir=infrastructure/projects/bootstrap output -raw sa_deployer_email | gh secret set DEPLOYER_SA      --repo $repo --body -
"<project_id_dev>" | gh secret set GCP_PROJECT_DEV --repo $repo --body -
"<project_id_prd>" | gh secret set GCP_PROJECT_PRD --repo $repo --body -
"<astro-token>"    | gh secret set ASTRO_API_TOKEN --repo $repo --body -
"<dep-dev>"        | gh secret set ASTRO_DEPLOYMENT_ID_DEV --repo $repo --body -
"<dep-prd>"        | gh secret set ASTRO_DEPLOYMENT_ID_PRD --repo $repo --body -
gh variable set GCP_REGION --repo $repo --body "europe-west1"
```

### Opção C — Interface web

Repositório GitHub → **Settings → Secrets and variables → Actions** → separador
**Secrets** (os da tabela) e separador **Variables** (`GCP_REGION`).

## 5. Provisionar os recursos do data product

Preenche [infrastructure/projects/resources/env_dev.tfvars](infrastructure/projects/resources/env_dev.tfvars)
com o `project_id`, `project_number` (output da bootstrap) e os emails das SAs.

```powershell
cd ../resources

terraform init -backend-config="bucket=<project_id_dev>-terraform-state"
terraform apply -var-file=env_dev.tfvars
```

Isto cria: datasets BigQuery (`internal`/`master`/`output_clear`/`monitoring`),
tabelas raw, buckets GCS e o Cloud Run Job do dbt (+ Artifact Registry).

> Em CI isto é feito automaticamente pelos workflows `terraform-plan` (em PR) e
> `terraform-apply` (em push para `dev`/`main`).

## 6. Construir e publicar a imagem dbt

Localmente:

```powershell
cd ../../../transformations/dbt/music_stream_rawdp
gcloud auth configure-docker europe-west1-docker.pkg.dev
docker build -t europe-west1-docker.pkg.dev/<project_id>/ar-music-stream-rawdp-d/dbt:latest .
docker push europe-west1-docker.pkg.dev/<project_id>/ar-music-stream-rawdp-d/dbt:latest
```

Em CI: o workflow `build-dbt-image` faz isto em push para `transformations/dbt/**`.

## 7. Orquestração (Airflow)

**Não precisas de conta na Astronomer.** O Astro CLI corre o Airflow localmente
em Docker, grátis:

```bash
cd app/astro
cp .env.example .env     # ajusta projetos/MONGO_URI se quiseres
astro dev start          # UI em http://localhost:8080 (admin/admin)
```

Deploy para a Astronomer Cloud (opcional): define no deployment as variáveis de
ambiente `GCP_PROJECT_DEV`, `GCP_PROJECT_PRD`, `GCP_REGION` e uma conexão GCP
(`google_cloud_default`), e corre o workflow `deploy-astro` manualmente
(Actions → Run workflow). Sem Astronomer, ignora este passo.

## Mapa de identidades (criadas pela bootstrap)

| Service Account | Uso | Roles principais |
| --------------- | --- | ---------------- |
| `sa-terraform-deployer` | CI provisiona infra (via WIF) | editor + admins específicos |
| `sa-astronomer` | orquestração / trigger Cloud Run | run.invoker, bigquery.jobUser, storage.objectAdmin |
| `sa-r-dataconsumption` | runner dbt | bigquery.dataEditor, bigquery.jobUser |
| `sa-ingestion` | ingestão Mongo→GCS | storage.objectAdmin, secretmanager.secretAccessor |

## Limpeza

```powershell
cd infrastructure/projects/resources
terraform destroy -var-file=env_dev.tfvars

cd ../bootstrap
terraform destroy -var-file=env_dev.tfvars
```
