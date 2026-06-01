#!/usr/bin/env bash
# Canlı PostgreSQL (DigitalOcean) üzerinde alembic migration
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "HATA: Önce DATABASE_URL export edin (DO Connection string)."
  exit 1
fi

echo "==> PostgreSQL driver + alembic"
python3 -m pip install -q psycopg2-binary alembic sqlalchemy python-dotenv

echo "==> alembic upgrade head"
if ! alembic upgrade head; then
  echo ""
  echo "NOT: Tablolar zaten varsa (users already exists):"
  echo "  alembic stamp b2c4e8f1a903"
  echo "  alembic upgrade head"
  echo "  psql \"\$DATABASE_URL\" -f scripts/sql/prod_missing_columns.sql"
  exit 1
fi

if command -v psql >/dev/null 2>&1; then
  echo "==> Eksik kolonlar (IF NOT EXISTS)"
  psql "$DATABASE_URL" -f "$ROOT/scripts/sql/prod_missing_columns.sql" || true
fi
