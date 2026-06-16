"""Generate fake music-streaming data and load it into the local MongoDB.

This script simulates the *operational* source system of the
``music-stream-rawdp`` data product. It populates four collections that mirror
the ingestion contracts declared under ``app/ingestion/sources``:

    Genre_ViewDP   -> genres
    Artist_ViewDP  -> artists
    Track_ViewDP   -> tracks
    Stream_ViewDP  -> stream (play) events

Everything is synthetic (generated with Faker). No real data is used.

Usage
-----
    docker compose up -d
    pip install -r seed/requirements.txt
    python seed/generate_seed_data.py            # default volumes
    python seed/generate_seed_data.py --tracks 5000 --streams 200000
"""

from __future__ import annotations

import argparse
import json
import os
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path

from faker import Faker
from pymongo import MongoClient

fake = Faker()
Faker.seed(42)
random.seed(42)

# --- configuration -----------------------------------------------------------

MONGO_URI = os.environ.get(
    "MONGO_URI", "mongodb://music_app:music_pw@localhost:27017/?authSource=admin"
)
DATABASE = os.environ.get("MONGO_DB", "music_streaming")

GENRE_NAMES = [
    "Pop", "Rock", "Hip-Hop", "Jazz", "Classical", "Electronic", "R&B",
    "Country", "Reggae", "Metal", "Folk", "Blues", "Soul", "Funk", "Indie",
]


def _now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def _ts_between(start_days_ago: int, end_days_ago: int = 0) -> datetime:
    start = _now() - timedelta(days=start_days_ago)
    end = _now() - timedelta(days=end_days_ago)
    return fake.date_time_between(start_date=start, end_date=end, tzinfo=timezone.utc).replace(
        microsecond=0
    )


# --- generators --------------------------------------------------------------

def gen_genres() -> list[dict]:
    docs = []
    for idx, name in enumerate(GENRE_NAMES, start=1):
        created = _ts_between(900, 400)
        docs.append(
            {
                "_id": f"GEN{idx:04d}",
                "ParentGenre": None if idx <= 5 else f"GEN{random.randint(1, 5):04d}",
                "Created": created,
                "Updated": _ts_between(390, 0),
                "Name": name,
                "PictureFile": f"genres/{name.lower().replace(' ', '_')}.png",
            }
        )
    return docs


def gen_artists(n: int) -> list[dict]:
    docs = []
    for idx in range(1, n + 1):
        created = _ts_between(800, 200)
        docs.append(
            {
                "_id": idx,
                "ArtistId": 100000 + idx,
                "Created": created,
                "Updated": _ts_between(190, 0),
                "Name": fake.name() if random.random() < 0.5 else fake.company(),
                "Description": fake.sentence(nb_words=12),
                "Country": fake.country_code(),
                "ExtendedProperties": [
                    {
                        "Context": "social",
                        "PropertyName": "followers",
                        "PropertyValue": str(random.randint(100, 50_000_000)),
                    },
                    {
                        "Context": "catalog",
                        "PropertyName": "verified",
                        "PropertyValue": random.choice(["true", "false"]),
                    },
                ],
                "IconFile": f"artists/{idx}/icon.png",
                "PosterFile": f"artists/{idx}/poster.png",
                "Type": random.choice([1, 2, 3]),
            }
        )
    return docs


def gen_tracks(n: int, artist_ids: list[int], genre_ids: list[str]) -> list[dict]:
    docs = []
    for idx in range(1, n + 1):
        created = _ts_between(700, 100)
        isrc = (
            f"{fake.country_code()}{fake.lexify('??').upper()}"
            f"{random.randint(10, 99)}{random.randint(10000, 99999)}"
        )
        docs.append(
            {
                "_id": idx,
                "Created": created,
                "Updated": _ts_between(90, 0),
                "Title": fake.sentence(nb_words=random.randint(1, 5)).rstrip("."),
                "Artist": random.choice(artist_ids),
                "DurationMs": random.randint(90_000, 480_000),
                "Album": fake.sentence(nb_words=random.randint(1, 4)).rstrip("."),
                "ReleaseYear": random.randint(1970, 2025),
                "Explicit": random.choice([True, False]),
                "Isrc": isrc,
                "TrackGenres": random.sample(genre_ids, k=random.randint(1, 3)),
                "Popularity": random.randint(0, 100),
                "Composers": [fake.name() for _ in range(random.randint(1, 3))],
                "MetadataTag": {
                    "_id": fake.uuid4(),
                    "Name": random.choice(["studio", "live", "remix", "acoustic"]),
                },
            }
        )
    return docs


def gen_streams(n: int, track_ids: list[int]) -> list[dict]:
    devices = ["mobile", "desktop", "smart_speaker", "tv", "web_player"]
    docs = []
    for idx in range(1, n + 1):
        begin = _ts_between(30, 0)
        duration = random.randint(5_000, 480_000)
        docs.append(
            {
                "_id": idx,
                "Created": begin,
                "Updated": begin,
                "UtcBeginDate": begin,
                "UtcEndDate": begin + timedelta(milliseconds=duration),
                "DurationMs": duration,
                "Track": random.choice(track_ids),
                "UserId": fake.uuid4(),
                "Device": random.choice(devices),
                "Country": fake.country_code(),
                "Completed": duration > 200_000,
                "Shuffle": random.choice([True, False]),
                "SkipReason": random.choice([None, None, None, "user_skip", "track_error"]),
            }
        )
    return docs


# --- load --------------------------------------------------------------------

def _add_ingestion_metadata(docs: list[dict]) -> list[dict]:
    ts = _now()
    for doc in docs:
        doc["ingestion_timestamp"] = ts
    return docs


def load(args: argparse.Namespace) -> None:
    print(f"Connecting to MongoDB at {MONGO_URI} ...")
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    db = client[DATABASE]

    genres = gen_genres()
    artists = gen_artists(args.artists)
    tracks = gen_tracks(args.tracks, [a["_id"] for a in artists], [g["_id"] for g in genres])
    streams = gen_streams(args.streams, [t["_id"] for t in tracks])

    collections = {
        "Genre_ViewDP": genres,
        "Artist_ViewDP": artists,
        "Track_ViewDP": tracks,
        "Stream_ViewDP": streams,
    }

    for name, docs in collections.items():
        col = db[name]
        col.drop()
        col.insert_many(_add_ingestion_metadata(docs))
        print(f"  {name:<16} -> {len(docs):>7} documents")

    if args.dump:
        out_dir = Path(__file__).parent / "output"
        out_dir.mkdir(exist_ok=True)
        for name, docs in collections.items():
            path = out_dir / f"{name}.json"
            path.write_text(json.dumps(docs, default=str, indent=2), encoding="utf-8")
        print(f"JSON snapshots written to {out_dir}")

    print("Done. Explore the data at http://localhost:8081 (mongo-express).")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Seed fake music-streaming data into MongoDB.")
    parser.add_argument("--artists", type=int, default=300, help="number of artists")
    parser.add_argument("--tracks", type=int, default=2000, help="number of tracks")
    parser.add_argument("--streams", type=int, default=50000, help="number of stream events")
    parser.add_argument("--dump", action="store_true", help="also dump JSON snapshots to seed/output")
    return parser.parse_args()


if __name__ == "__main__":
    load(parse_args())
