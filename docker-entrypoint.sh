#!/bin/sh
set -e

log() {
    echo "[entrypoint] $@"
}

if [ "$1" = 'tor' ] && [ "$(id -u)" = '0' ]; then
    log "Fixing permissions for /var/lib/tor..."

    chown -R tor:tor /var/lib/tor
    chmod 700 /var/lib/tor

    if [ -f "/etc/tor/torrc" ]; then
        chown tor:tor /etc/tor/torrc 2>/dev/null || true
    fi

    log "Dropping privileges to user 'tor'..."
    exec su-exec tor "$@"
fi

exec "$@"
