# app/ — Applications

Código aplicacional do data product `music-stream-rawdp`.

## `astro/` — Orquestração (Airflow)

Projeto **Astro** standard. Corre o Airflow **localmente e de graça** com o
[Astro CLI](https://www.astronomer.io/docs/astro/cli/install-cli) — **não é
preciso conta na Astronomer Cloud**:

```bash
cd app/astro
astro dev start        # arranca Airflow em Docker (UI em http://localhost:8080)
```

> O deploy para a Astronomer Cloud (`deploy-astro` workflow) é totalmente
> opcional e manual. Para portefólio basta o run local acima.

### Estrutura

| Caminho | Descrição |
| ------- | --------- |
| `Dockerfile` | Imagem Astro Runtime (Airflow gerido). |
| `requirements.txt` / `packages.txt` | Dependências Python / SO. |
| `music_stream_rawdp/base.py` | Configuração central: projetos GCP (fictícios), região, tabelas/entidades, coleção MongoDB de origem e schemas BigQuery. Importado como `music_stream_rawdp.base`. |
| `dags/dag-music-stream-rawdp-etl.py` | DAG ETL: extração MongoDB → GCS → BigQuery → dbt, por entidade. |
| `dags/dag-music-stream-rawdp-monitoring.py` | DAG de monitoria/data quality (dbt `monitoring`). |
| `include/` | Operador de ingestão próprio + callbacks. |

### `include/`

| Módulo | Descrição |
| ------ | --------- |
| `mongo_ingestion_operator.py` | **`MongoToGCSIngestionOperator`** — operador funcional que lê uma coleção MongoDB, enriquece com metadados (`airflow_ds`, `ingestion_timestamp`) e escreve NDJSON num prefixo GCS particionado por data. |
| `callbacks.py` | Callbacks de _logging_ (substituem um hub central de orquestração). |
| `dbt_operator.py` | Operador dbt _placeholder_ (a execução real corre como Cloud Run Job). |

> Não é usada qualquer plataforma proprietária de ingestão ou serviço de
> transferência de dados — a ingestão é feita exclusivamente pelo operador
> próprio acima, que funciona contra o MongoDB local de `docker-compose.yml`.

## `ingestion/` — Contratos declarativos de ingestão

- `connections/` — definição da ligação MongoDB (credenciais via `${secrets.*}`).
- `sources/` — um JSON por entidade (`genre`, `artist`, `track`, `stream`)
  descrevendo a fonte MongoDB (database/coleção) e o destino (`sink`: bucket GCS,
  formato e tabela BigQuery), num **formato próprio e simples**.

A fonte real é substituída pelo MongoDB local definido em `docker-compose.yml`
e populado por `seed/generate_seed_data.py`.
