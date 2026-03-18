# HE Tunnelbroker (6in4)

## What does this add-on do?

This add-on gives your Home Assistant host **IPv6 connectivity** by creating a tunnel to [Hurricane Electric's free Tunnelbroker service](https://tunnelbroker.net/). 

If your internet provider doesn't offer native IPv6, this add-on encapsulates IPv6 traffic inside your existing IPv4 connection (a technique called "6in4" or "SIT tunneling") — giving you a fully routable, globally reachable IPv6 address.

## Features

- **Automatic IPv4 detection** — set `client_ipv4` to `"auto"` and the add-on detects your public IP at startup
- **Dynamic IP support** — automatically updates your tunnel endpoint at HE when your IPv4 address changes
- **Health monitoring** — periodically pings an IPv6 host and automatically restarts the tunnel if connectivity is lost
- **Graceful shutdown** — cleanly removes the tunnel interface when the add-on stops
- **Configurable DNS** — adds IPv6 DNS servers to the host resolver
- **Zero dependencies** — runs entirely within the add-on container, no additional software needed on the host

## Prerequisites

Before you start, make sure you have:

1. A **free account** at [tunnelbroker.net](https://tunnelbroker.net/)
2. A **configured tunnel** — create one on the HE website (choose a server close to you, e.g. Frankfurt for Germany)
3. A **public IPv4 address** — this will NOT work behind CGNAT or DS-Lite
4. **Protocol 41** allowed through your router/firewall — this is an IP protocol (not a TCP/UDP port)

## Quick Start

1. Go to your tunnel details page on [tunnelbroker.net](https://tunnelbroker.net/)
2. Copy the values into the add-on configuration:
   - **Server IPv4 Address** → `server_ipv4`
   - **Server IPv6 Address** → `server_ipv6`  
   - **Client IPv6 Address** → `client_ipv6`
   - **Routed /64** → `routed_subnet`
3. Set `client_ipv4` to `"auto"` (or enter your public IPv4 manually)
4. If you have a dynamic IP, enable `update_enabled` and fill in your HE credentials
5. Click **Start**
6. Check the **Log** tab — you should see "Health check: IPv6 connectivity OK."

## Configuration Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server_ipv4` | string | _(required)_ | HE tunnel server IPv4 address |
| `client_ipv4` | string | `"auto"` | Your public IPv4, or `"auto"` to detect |
| `server_ipv6` | string | _(required)_ | HE tunnel server IPv6 endpoint |
| `client_ipv6` | string | _(required)_ | Your tunnel IPv6 address |
| `routed_subnet` | string | _(required)_ | Your routed /64 or /48 subnet |
| `tunnel_mtu` | int | `1480` | Tunnel MTU (reduce if you see packet loss) |
| `update_enabled` | bool | `false` | Auto-update IPv4 endpoint at HE |
| `update_username` | string | | HE account username |
| `update_key` | password | | Tunnel Update Key (not your password!) |
| `update_tunnel_id` | string | | Numeric tunnel ID |
| `update_interval` | int | `600` | Seconds between IP change checks |
| `dns_servers` | list | Google DNS | IPv6 DNS servers to configure |
| `healthcheck_host` | string | `2001:4860:4860::8888` | IPv6 host to ping for health checks |
| `healthcheck_interval` | int | `300` | Seconds between health checks |
| `notify_on_start` | bool | `false` | Send a HA notification when the tunnel comes up |

## Troubleshooting

### The add-on starts but health check fails

- **Protocol 41 blocked**: Your router or ISP may block IP Protocol 41. Check your router's firewall settings. Some routers have a specific "IPv6 tunnel" or "Protocol 41 passthrough" option.
- **Wrong IPv4**: Make sure HE has your current public IPv4. Go to your tunnel details on tunnelbroker.net and click "Update" or enable `update_enabled`.
- **MTU issues**: Try reducing `tunnel_mtu` to `1452` (accounts for PPPoE overhead) or even `1400`.

### "modprobe sit failed"

This is usually just a warning. The `sit` kernel module may already be built into the kernel. If tunnel creation also fails, your kernel may not support IPv6 tunneling — this is rare on standard HAOS installations.

### "Failed to create SIT tunnel"

The `NET_ADMIN` privilege may not be active. Reinstall the add-on and make sure you don't have any security restrictions overriding the add-on's privilege requests.

### CGNAT / DS-Lite detection

If `client_ipv4` is set to `"auto"` and the detected IP doesn't match your router's WAN IP, you're likely behind CGNAT. The tunnel will not work in this case. Contact your ISP to request a public IPv4 address, or check if they offer native IPv6.

## Security Notice

Once the tunnel is active, your Home Assistant host has a **globally routable IPv6 address**. Unlike IPv4 behind NAT, IPv6 traffic is **not** address-translated — devices are directly reachable from the internet. Make sure you have appropriate firewall rules in place.

## How It Works

1. The add-on validates configuration and detects the public IPv4 (if set to auto)
2. It loads the `sit` kernel module and creates a SIT tunnel to the HE server
3. The tunnel interface receives your IPv6 address and a default IPv6 route is set
4. A health check loop monitors connectivity and auto-restarts the tunnel if it goes down
5. If dynamic IP updates are enabled, the add-on watches for IPv4 changes and updates both HE and the local tunnel endpoint
6. On shutdown, the tunnel is cleanly removed
