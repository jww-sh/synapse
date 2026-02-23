#!/usr/bin/env bash
set -e

if [ -d "${PLATFORM_CACHE_DIR:-}" ]; then
    PIP_CACHE="--cache-dir=${PLATFORM_CACHE_DIR}/pip"
fi

printf "\n  ✔ \033[1mInstalling Synapse\033[0m (latest)\n\n"
# [postgres] extra pulls in psycopg2 for PostgreSQL support
pip install ${PIP_CACHE:-} "matrix-synapse[postgres]"
