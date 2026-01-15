#!/bin/sh

# fix for Nokogiri on arm64; helps to install platform agnostic/specific software
bundle lock --add-platform ruby
bundler install

# Make these available via Settings in the app
export SETTINGS__GIT_COMMIT="$APP_GIT_COMMIT"
export SETTINGS__BUILD_DATE="$APP_BUILD_DATE"
export SETTINGS__GIT_SOURCE="$APP_BUILD_TAG"

mkdir -p log

set -ex

# Preflight: Ensure psql client tools are available in PATH
if ! command -v psql >/dev/null 2>&1; then
  echo "Error: 'psql' is not installed or not found in PATH." >&2
  echo "Please ensure PostgreSQL client tools are installed and PATH is set, or rebuild the dev image." >&2
  echo "On Alpine-based images this is provided by the postgresql-client package." >&2
  exit 127
fi
if ! command -v pg_isready >/dev/null 2>&1; then
  echo "Error: 'pg_isready' is not installed or not found in PATH." >&2
  echo "Please ensure PostgreSQL client tools are installed and PATH is set, or rebuild the dev image." >&2
  exit 127
fi

# Wait for Postgres to be ready (host provided by docker-compose service name)
DB_HOST="${PGHOST:-db}"
DB_PORT="${PGPORT:-5432}"
DB_USER="${PGUSER:-postgres}"

echo "Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
for i in $(seq 1 60); do
  if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; then
    echo "Postgres is ready."
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    echo "Postgres did not become ready in time" >&2
    exit 1
  fi
done

rails db:setup
rails db:migrate
rails db:seed


# load pseudo users
rake db:seed:dev

# install yarn dependencies
npm install --global yarn
yarn install
