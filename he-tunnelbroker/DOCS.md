# HE Tunnelbroker (6in4) — Documentation

## Overview

This add-on creates a 6in4 (SIT / Protocol 41) IPv6 tunnel to [Hurricane Electric's Tunnelbroker service](https://tunnelbroker.net/). It configures the tunnel directly on the Home Assistant OS host, assigns your IPv6 tunnel address, and sets up a default IPv6 route so that the entire host gains IPv6 connectivity.

## Configuration Reference

### `server_ipv4` (required)

**Type:** `str`

The IPv4 address of the Hurricane Electric tunnel server. You can find this value on your tunnel's detail page as **Server IPv4 Address**.

### `client_ipv4` (required)

**Type:** `str`

Your public-facing IPv4 address. Set this to `"auto"` to have the add-on detect it automatically at startup using `ipv4.icanhazip.com`. Use `"auto"` if you have a dynamic IP address.

### `server_ipv6` (required)

**Type:** `str`

The server-side IPv6 address of the tunnel (e.g. `2001:470:1f0a:xxxx::1`). Found as **Server IPv6 Address** in the HE tunnel details.

### `client_ipv6` (required)

**Type:** `str`

Your assigned tunnel IPv6 address (e.g. `2001:470:1f0a:xxxx::2`). Found as **Client IPv6 Address** in the HE tunnel details.

### `routed_subnet` (required)

**Type:** `str`

The routed IPv6 subnet assigned by HE (e.g. `2001:470:1f0b:xxxx::/64`). This can be used to assign IPv6 addresses to other devices on your network.

### `tunnel_mtu`

**Type:** `int`  
**Default:** `1480`

The MTU (Maximum Transmission Unit) for the tunnel interface. The standard is 1480 (1500 bytes minus the 20-byte IPv4 encapsulation header). If you experience packet loss or connection issues with large payloads, try reducing this value to `1452` or lower.

### `update_enabled`

**Type:** `bool`  
**Default:** `false`

Enables automatic endpoint updates via the HE dynamic DNS API. Set to `true` if your public IPv4 address changes (dynamic IP). When enabled, the add-on periodically checks your current public IP and updates the HE tunnel endpoint if it has changed.

### `update_username`

**Type:** `str`

Your Hurricane Electric account username.

### `update_key`

**Type:** `password`

The **Tunnel Update Key** from your HE tunnel's **Advanced** section. This is a separate key from your account password and is safe to use without exposing your login credentials.

### `update_tunnel_id`

**Type:** `str`

The numeric ID of your tunnel. Visible in the URL and header of your tunnel's detail page on tunnelbroker.net.

### `update_interval`

**Type:** `int`  
**Default:** `600`

How often (in seconds) the add-on checks for IP address changes and updates the HE endpoint. The minimum recommended value is `300` (5 minutes) to avoid triggering HE's rate limits.

### `dns_servers`

**Type:** `list(str)`  
**Default:** `["2001:4860:4860::8888", "2001:4860:4860::8844"]`

IPv6 DNS servers to add to the host's `/etc/resolv.conf`. Defaults to Google's public IPv6 DNS resolvers.

### `healthcheck_host`

**Type:** `str`  
**Default:** `"2001:4860:4860::8888"`

The IPv6 address used for periodic connectivity health checks. The add-on pings this host every `healthcheck_interval` seconds. If the ping fails the tunnel is automatically restarted. Change this to any reliably reachable IPv6 host.

### `healthcheck_interval`

**Type:** `int` (60–3600)  
**Default:** `300`

How often (in seconds) the add-on performs the IPv6 connectivity health check and, if `update_enabled` is `true`, checks for IP address changes. Valid range: 60–3600 seconds.

## How It Works

1. At startup the add-on reads the configuration via `bashio`.
2. Required fields (`server_ipv4`, `server_ipv6`, `client_ipv6`) are validated — the add-on exits with a fatal error if they are empty or still contain placeholder values.
3. If `client_ipv4` is `"auto"`, it fetches the current public IPv4 from `ipv4.icanhazip.com`.
4. It attempts to load the `sit` kernel module (ignores failure — it may already be loaded).
5. Any previously existing `he-ipv6` tunnel is removed to ensure a clean state.
6. The SIT tunnel is created with `ip tunnel add`, brought up, and configured with the correct IPv6 address and default route.
7. Optional IPv6 DNS servers are appended to `/etc/resolv.conf`.
8. The add-on enters its main loop. Every `healthcheck_interval` seconds it pings the configured health-check host. If the ping fails, the tunnel is automatically restarted. If it still fails after the restart an error is logged.
9. If `update_enabled` is `true`, the add-on also checks for public IP changes on every loop iteration and updates the HE endpoint accordingly.
10. On SIGTERM/SIGINT the tunnel is gracefully removed.
