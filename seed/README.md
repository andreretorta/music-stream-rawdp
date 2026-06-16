# seed/ — Fake operational source

Este módulo substitui o sistema operacional MongoDB corporativo do projeto original
por uma **fonte fictícia local**, gerada com [Faker](https://faker.readthedocs.io/).

## Coleções geradas

| Coleção MongoDB | Documentos (default) |
| --------------- | -------------------- |
| `Genre_ViewDP`  | 15 |
| `Artist_ViewDP` | 300 |
| `Track_ViewDP`  | 2 000 |
| `Stream_ViewDP` | 50 000 |

## Utilização

```powershell
docker compose up -d
pip install -r seed/requirements.txt
python seed/generate_seed_data.py
```

Variáveis de ambiente suportadas: `MONGO_URI`, `MONGO_DB`.

Para volumes maiores / dumps JSON:

```powershell
python seed/generate_seed_data.py --tracks 10000 --streams 500000 --dump
```
