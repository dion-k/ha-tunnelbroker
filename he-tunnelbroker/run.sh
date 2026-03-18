#!/usr/bin/env bashio

# ──────────────────────────────────────────────
#  HE Tunnelbroker (6in4) – run.sh
#  Sets up a SIT (Protocol 41) tunnel to
#  Hurricane Electric Tunnelbroker and keeps it
#  alive, optionally updating the remote endpoint.
# ──────────────────────────────────────────────

TUNNEL_NAME="he-ipv6"

# ── Graceful shutdown ──────────────────────────
cleanup() {
    bashio::log.info "Shutting down HE Tunnelbroker add-on..."
    ip tunnel del "${TUNNEL_NAME}" 2>/dev/null || true
    bashio::log.info "Tunnel '${TUNNEL_NAME}' removed."
    exit 0
}
trap 'cleanup' SIGTERM SIGINT

# ── Load configuration ─────────────────────────
SERVER_IPV4=$(bashio::config 'server_ipv4')
CLIENT_IPV4=$(bashio::config 'client_ipv4')
SERVER_IPV6=$(bashio::config 'server_ipv6')
CLIENT_IPV6=$(bashio::config 'client_ipv6')
ROUTED_SUBNET=$(bashio::config 'routed_subnet')
TUNNEL_MTU=$(bashio::config 'tunnel_mtu')
UPDATE_ENABLED=$(bashio::config 'update_enabled')
UPDATE_USERNAME=$(bashio::config 'update_username')
UPDATE_KEY=$(bashio::config 'update_key')
UPDATE_TUNNEL_ID=$(bashio::config 'update_tunnel_id')
UPDATE_INTERVAL=$(bashio::config 'update_interval')

bashio::log.info "Starting HE Tunnelbroker (6in4) add-on..."

# ── Auto-detect public IPv4 ────────────────────
if [ "${CLIENT_IPV4}" = "auto" ]; then
    bashio::log.info "Auto-detecting public IPv4 address..."
    CLIENT_IPV4=$(curl -sf --max-time 10 https://ipv4.icanhazip.com || true)
    if [ -z "${CLIENT_IPV4}" ]; then
        CLIENT_IPV4=$(curl -sf --max-time 10 https://api4.ipify.org || true)
    fi
    if [ -z "${CLIENT_IPV4}" ]; then
        bashio::log.error "Failed to auto-detect public IPv4 address. Please set client_ipv4 manually."
        exit 1
    fi
    bashio::log.info "Detected public IPv4: ${CLIENT_IPV4}"
fi

# ── Check/load sit kernel module ──────────────
bashio::log.info "Checking for SIT (sit) kernel module..."
if modprobe sit 2>/dev/null; then
    bashio::log.info "SIT module loaded successfully."
else
    bashio::log.warning "modprobe sit failed – the module may already be built into the kernel. Continuing..."
fi

if [ ! -f /proc/net/if_inet6 ]; then
    bashio::log.warning "/proc/net/if_inet6 not found – IPv6 may not be available in this kernel."
fi

# ── Helper: bring up the tunnel ───────────────
setup_tunnel() {
    local local_ipv4="${1}"

    ip tunnel del "${TUNNEL_NAME}" 2>/dev/null || true

    if ! ip tunnel add "${TUNNEL_NAME}" mode sit \
            remote "${SERVER_IPV4}" \
            local  "${local_ipv4}" \
            ttl 255; then
        bashio::log.error "Failed to create SIT tunnel. Check that NET_ADMIN privilege is granted and the sit module is available."
        return 1
    fi

    ip link set "${TUNNEL_NAME}" mtu "${TUNNEL_MTU}"
    ip link set "${TUNNEL_NAME}" up

    if ! ip addr add "${CLIENT_IPV6}/64" dev "${TUNNEL_NAME}" 2>/dev/null; then
        bashio::log.warning "Failed to add IPv6 address ${CLIENT_IPV6}/64 – it may already be configured."
    fi

    if ! ip -6 route add ::/0 dev "${TUNNEL_NAME}" 2>/dev/null; then
        bashio::log.warning "Failed to add default IPv6 route – a default route may already exist."
    fi

    bashio::log.info "Tunnel '${TUNNEL_NAME}' is up (local=${local_ipv4}, remote=${SERVER_IPV4}, mtu=${TUNNEL_MTU})."
}

# ── Build the tunnel ───────────────────────────
bashio::log.info "Creating tunnel: ${TUNNEL_NAME}"
bashio::log.info "  Server IPv4  : ${SERVER_IPV4}"
bashio::log.info "  Client IPv4  : ${CLIENT_IPV4}"
bashio::log.info "  Server IPv6  : ${SERVER_IPV6}"
bashio::log.info "  Client IPv6  : ${CLIENT_IPV6}"
bashio::log.info "  Routed subnet: ${ROUTED_SUBNET}"
bashio::log.info "  MTU          : ${TUNNEL_MTU}"

if ! setup_tunnel "${CLIENT_IPV4}"; then
    exit 1
fi

# ── Configure DNS ──────────────────────────────
if bashio::config.has_value 'dns_servers'; then
    bashio::log.info "Configuring IPv6 DNS servers..."
    for dns in $(bashio::config 'dns_servers[]'); do
        if ! grep -qF "nameserver ${dns}" /etc/resolv.conf 2>/dev/null; then
            echo "nameserver ${dns}" >> /etc/resolv.conf
            bashio::log.info "Added DNS server: ${dns}"
        fi
    done
fi

# ── Helper: update HE endpoint ─────────────────
update_he_endpoint() {
    local new_ipv4
    new_ipv4=$(curl -sf --max-time 10 https://ipv4.icanhazip.com || true)
    if [ -z "${new_ipv4}" ]; then
        new_ipv4=$(curl -sf --max-time 10 https://api4.ipify.org || true)
    fi

    if [ -z "${new_ipv4}" ]; then
        bashio::log.warning "Could not detect current public IPv4 – skipping update."
        return
    fi

    if [ "${new_ipv4}" != "${CLIENT_IPV4}" ]; then
        bashio::log.info "Public IPv4 changed: ${CLIENT_IPV4} → ${new_ipv4}. Updating HE endpoint..."
        local response
        response=$(curl -sf --max-time 15 \
            "https://${UPDATE_USERNAME}:${UPDATE_KEY}@ipv4.tunnelbroker.net/nic/update?hostname=${UPDATE_TUNNEL_ID}" \
            || echo "CURL_ERROR")

        if [ "${response}" = "CURL_ERROR" ]; then
            bashio::log.error "HE endpoint update request failed (curl error)."
        else
            bashio::log.info "HE update response: ${response}"
        fi

        bashio::log.info "Rebuilding tunnel with new local endpoint ${new_ipv4}..."
        if setup_tunnel "${new_ipv4}"; then
            CLIENT_IPV4="${new_ipv4}"
            bashio::log.info "Tunnel endpoint updated successfully."
        else
            bashio::log.error "Failed to rebuild tunnel after IP change."
        fi
    fi
}

# ── Helper: health check ───────────────────────
health_check() {
    if ping6 -c 1 -W 5 2001:4860:4860::8888 >/dev/null 2>&1; then
        bashio::log.info "Health check: IPv6 connectivity OK."
    else
        bashio::log.warning "Health check: IPv6 ping to 2001:4860:4860::8888 failed. Tunnel may be degraded."
    fi
}

# ── Main keep-alive loop ───────────────────────
bashio::log.info "Entering main loop (update_interval=${UPDATE_INTERVAL}s)..."

HEALTH_CHECK_INTERVAL=300  # run health check at least every 5 minutes
LAST_HEALTH_CHECK=$(date +%s)
health_check

while true; do
    sleep "${UPDATE_INTERVAL}" &
    wait $!

    if bashio::var.true "${UPDATE_ENABLED}"; then
        update_he_endpoint
    fi

    NOW=$(date +%s)
    if [ $((NOW - LAST_HEALTH_CHECK)) -ge "${HEALTH_CHECK_INTERVAL}" ]; then
        health_check
        LAST_HEALTH_CHECK="${NOW}"
    fi
done
