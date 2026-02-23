#!/usr/bin/env bash
set -e

# Admin user created on first deploy
PSH_ADMIN_USERNAME="${PSH_ADMIN_USERNAME:-admin}"
PSH_ADMIN_EMAIL="${PSH_ADMIN_EMAIL:-admin@example.com}"

# Extract PostgreSQL connection info from platform relationships
DB_HOST=$(echo "$PLATFORM_RELATIONSHIPS" | base64 --decode | jq -r ".database[0].host")
DB_PORT=$(echo "$PLATFORM_RELATIONSHIPS" | base64 --decode | jq -r ".database[0].port")
DB_NAME=$(echo "$PLATFORM_RELATIONSHIPS" | base64 --decode | jq -r ".database[0].path")
DB_USER=$(echo "$PLATFORM_RELATIONSHIPS" | base64 --decode | jq -r ".database[0].username")
DB_PASS=$(echo "$PLATFORM_RELATIONSHIPS" | base64 --decode | jq -r ".database[0].password")

# Derive server name from the primary route (e.g. "matrix.example.com")
SERVER_NAME=$(echo "$PLATFORM_ROUTES" | base64 --decode | \
    jq -r 'to_entries[] | select(.value.primary) | .key' | \
    sed 's|https\?://||;s|/$||')

# Generate persistent secrets on first deploy only
if [ ! -f data/secrets ]; then
    printf "\n  ✔ \033[1mGenerating secrets...\033[0m\n"
    printf "REGISTRATION_SECRET=%s\n" "$(openssl rand -hex 32)" >  data/secrets
    printf "MACAROON_SECRET=%s\n"     "$(openssl rand -hex 32)" >> data/secrets
    printf "FORM_SECRET=%s\n"         "$(openssl rand -hex 32)" >> data/secrets
fi
# shellcheck source=/dev/null
. data/secrets

# Generate the Matrix signing key on first deploy only
if [ ! -f data/homeserver.signing.key ]; then
    printf "\n  ✔ \033[1mGenerating signing key...\033[0m\n"
    python -c "
from signedjson.key import generate_signing_key, write_signing_keys
write_signing_keys(open('data/homeserver.signing.key', 'w'), [generate_signing_key('auto')])
"
fi

# Write structured log config once
if [ ! -f data/log.yaml ]; then
    cat > data/log.yaml <<'LOGEOF'
version: 1
formatters:
  precise:
    format: '%(asctime)s - %(name)s - %(lineno)d - %(levelname)s - %(request)s - %(message)s'
handlers:
  console:
    class: logging.StreamHandler
    formatter: precise
loggers:
  synapse.storage.SQL:
    level: WARNING
root:
  level: INFO
  handlers: [console]
disable_existing_loggers: false
LOGEOF
fi

# Regenerate homeserver.yaml on every deploy so PORT and DB changes are picked up
printf "\n  ✔ \033[1mWriting homeserver.yaml\033[0m (server: %s, port: %s)\n" \
    "$SERVER_NAME" "${PORT:-8008}"

cat > data/homeserver.yaml <<EOF
server_name: "$SERVER_NAME"
pid_file: /app/data/homeserver.pid

listeners:
  - port: ${PORT:-8008}
    bind_addresses: ['0.0.0.0']
    tls: false
    type: http
    x_forwarded: true
    resources:
      - names: [client, federation]
        compress: false

database:
  name: psycopg2
  args:
    user: $DB_USER
    password: $DB_PASS
    database: $DB_NAME
    host: $DB_HOST
    port: $DB_PORT
    cp_min: 5
    cp_max: 10

media_store_path: /app/media

signing_key_path: /app/data/homeserver.signing.key
log_config: /app/data/log.yaml

registration_shared_secret: "$REGISTRATION_SECRET"
macaroon_secret_key: "$MACAROON_SECRET"
form_secret: "$FORM_SECRET"

# Registration is off by default — enable via environment variable if needed
enable_registration: false

report_stats: false

trusted_key_servers:
  - server_name: "matrix.org"
EOF
