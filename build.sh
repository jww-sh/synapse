#!/usr/bin/env bash
set -e

SYNAPSE_VERSION=$(cat synapse_version)

if [ -d "${PLATFORM_CACHE_DIR:-}" ]; then
    PIP_CACHE="--cache-dir=${PLATFORM_CACHE_DIR}/pip"
fi

printf "\n  ✔ \033[1mInstalling Synapse\033[0m (%s)\n\n" "$SYNAPSE_VERSION"
# [postgres] extra pulls in psycopg2 for PostgreSQL support
pip install ${PIP_CACHE:-} "matrix-synapse[postgres]==${SYNAPSE_VERSION}"
