# Goriva Parser

Fetches Slovenian fuel prices from goriva.si and enriches MOL & INA station data from the MOL station locator API.

## Running

```bash
uv run uvicorn app.main:app --reload
```

Or with Docker:

```bash
docker compose up -d
```

## Database migrations

Migrations are **not** applied automatically. Run them manually before starting the app.

```bash
uv run alembic upgrade head
```

To check current migration state:

```bash
uv run alembic current
```

To roll back one migration:

```bash
uv run alembic downgrade -1
```

Typical deploy sequence:

```bash
docker compose run --rm goriva-parser uv run alembic upgrade head
docker compose up -d
```

## Background jobs

| Job | Interval | Description |
|---|---|---|
| `hourly_fetch` | Every 1h (configurable) | Fetches fuel prices from goriva.si |
| `daily_reference` | Every 24h | Refreshes fuel types and franchises |
| `daily_mol_sync` | Every 24h + on startup | Syncs MOL & INA station data from iskalnik.mol.si |

The MOL sync runs once immediately on every app start, then every 24 hours. Restarting the app triggers a fresh sync.

## Configuration

Environment variables (or `.env` file):

| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `sqlite+aiosqlite:///./data/goriva.db` | Database connection string |
| `FETCH_INTERVAL_HOURS` | `1` | Price fetch interval in hours |
| `GORIVA_BASE_URL` | `https://goriva.si` | Base URL for goriva.si API |

## API

Base path: `/api/v1`

| Endpoint | Description |
|---|---|
| `GET /prices` | All stations with latest fuel prices |
| `GET /stations` | All stations with latest prices and MOL data |
| `GET /stations/{pk}` | Single station |
| `GET /stations/{pk}/prices` | Price history for a station |
| `GET /franchises` | All franchises |
| `GET /fuels` | All fuel types |
| `GET /fetch-log` | Recent fetch operations |
