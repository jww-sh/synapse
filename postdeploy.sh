#!/usr/bin/env bash

wait_for_synapse() {
    local max_wait=60
    local waited=0
    printf "\n  Waiting for Synapse to start"
    while [ $waited -lt $max_wait ]; do
        if curl -sf "http://localhost:${PORT:-8008}/_matrix/client/versions" > /dev/null 2>&1; then
            printf " ✔\n"
            return 0
        fi
        printf "."
        sleep 2
        waited=$((waited + 2))
    done
    printf "\n  Warning: Synapse did not respond after %ss\n" "$max_wait" >&2
    return 1
}

first_deploy() {
    printf "\n\033[1mInitializing Synapse on first deploy...\033[0m\n"
    wait_for_synapse || exit 1

    # Derive server name from the running config
    SERVER_NAME=$(grep '^server_name:' data/homeserver.yaml | sed 's/server_name: "\(.*\)"/\1/')

    # Generate a secure random admin password
    ADMIN_PASSWORD="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 20)!9Aa"

    printf "\n  ✔ \033[1mRegistering admin user\033[0m (@%s:%s)\n" \
        "$PSH_ADMIN_USERNAME" "$SERVER_NAME"

    register_new_matrix_user \
        -c data/homeserver.yaml \
        --user  "$PSH_ADMIN_USERNAME" \
        --password "$ADMIN_PASSWORD" \
        --admin \
        "http://localhost:${PORT:-8008}"

    printf "%s" "$ADMIN_PASSWORD" > data/admin_credentials
    chmod 600 data/admin_credentials

    printf "\n\n\033[1mSynapse is ready!\033[0m\n"
    printf "  Matrix ID : @%s:%s\n" "$PSH_ADMIN_USERNAME" "$SERVER_NAME"
    printf "  Password  : retrieve via SSH with: \`cat /app/data/admin_credentials\`\n"
    printf "\n  \033[33mWARNING: Change your password immediately after first login!\033[0m\n\n"

    touch data/synapse.installed
}

if [ ! -f data/synapse.installed ]; then
    first_deploy
fi
