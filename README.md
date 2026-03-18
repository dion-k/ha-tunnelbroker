# Home Assistant Add-on: HE Tunnelbroker (6in4)

[![GitHub Release][releases-shield]][releases]
[![License][license-shield]](LICENSE)
![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armhf Architecture][armhf-shield]
![Supports armv7 Architecture][armv7-shield]
![Supports i386 Architecture][i386-shield]

Establishes a **6in4 IPv6 tunnel** (SIT / Protocol 41) to [Hurricane Electric's free Tunnelbroker service](https://tunnelbroker.net/), providing native IPv6 connectivity to your Home Assistant host.

## About

Hurricane Electric (HE) offers free IPv6 tunnels via their Tunnelbroker service. This add-on sets up the required SIT tunnel directly on the Home Assistant OS host network stack, assigns your IPv6 address, and optionally keeps the tunnel endpoint up-to-date when your public IPv4 address changes (dynamic IP support).

## Prerequisites

- A free account at [tunnelbroker.net](https://tunnelbroker.net/) with a configured tunnel
- A public IPv4 address (static or dynamic) — NAT/CGNAT will **not** work
- **Protocol 41** (IPv6-in-IPv4) must be allowed through your firewall/router
- Home Assistant OS (HassOS) or a supervised installation on Linux

> **Security note:** Once the tunnel is active, your Home Assistant host will have a globally routable IPv6 address. Make sure your firewall rules account for this — IPv6 traffic is **not** NAT-ed.

## Installation

1. Navigate to **Settings → Add-ons → Add-on Store** in Home Assistant.
2. Click the **⋮** menu in the top-right corner and select **Repositories**.
3. Add the repository URL: `https://github.com/dion-k/ha-tunnelbroker`
4. Find **HE Tunnelbroker (6in4)** in the store and click **Install**.
5. Configure the add-on (see below), then click **Start**.

## Configuration

Example configuration:

```yaml
server_ipv4: "216.66.80.90"
client_ipv4: "auto"
server_ipv6: "2001:470:1f0a:xxxx::1"
client_ipv6: "2001:470:1f0a:xxxx::2"
routed_subnet: "2001:470:1f0b:xxxx::/64"
tunnel_mtu: 1480
update_enabled: true
update_username: "your_he_username"
update_key: "your_tunnel_update_key"
update_tunnel_id: "your_tunnel_id"
update_interval: 600
dns_servers:
  - "2001:4860:4860::8888"
  - "2001:4860:4860::8844"
```

### Option: `server_ipv4`

The IPv4 address of the HE tunnel server endpoint. Find this in your tunnel details page under **Server IPv4 Address**.

### Option: `client_ipv4`

Your public IPv4 address. Set to `"auto"` to detect it automatically at startup (recommended for dynamic IP addresses).

### Option: `server_ipv6`

The server-side IPv6 address of the tunnel (e.g. `2001:470:1f0a:xxxx::1`). Listed as **Server IPv6 Address** in the HE tunnel details.

### Option: `client_ipv6`

Your side of the tunnel IPv6 address (e.g. `2001:470:1f0a:xxxx::2`). Listed as **Client IPv6 Address** in the HE tunnel details.

### Option: `routed_subnet`

The routed /64 (or /48) subnet assigned to you by HE (e.g. `2001:470:1f0b:xxxx::/64`). This subnet can be used to assign IPv6 addresses to devices on your network.

### Option: `tunnel_mtu`

MTU for the tunnel interface. Default is `1480` (1500 - 20 bytes IPv4 header). Reduce this if you experience fragmentation issues.

### Option: `update_enabled`

Set to `true` to enable automatic IPv4 endpoint updates via the HE dynamic DNS API. Required if your ISP assigns a dynamic IPv4 address.

### Option: `update_username`

Your Hurricane Electric account username.

### Option: `update_key`

The **Tunnel Update Key** found in your HE tunnel details (under **Advanced** → **Tunnel Update Key**). This is **not** your account password.

### Option: `update_tunnel_id`

The numeric tunnel ID shown in the HE tunnel details page URL and header.

### Option: `update_interval`

How often (in seconds) to check for IP changes and update the HE endpoint. Default is `600` (10 minutes).

### Option: `dns_servers`

A list of IPv6 DNS servers to configure. Defaults to Google's public IPv6 DNS servers.

## Troubleshooting

### "modprobe sit failed"

The `sit` kernel module may already be built into the kernel (common on many SBCs and VMs). This is a warning, not an error — the add-on will continue. If tunnel creation still fails, your kernel may not have IPv6 tunnel support compiled in.

### Tunnel up but no IPv6 connectivity

1. Verify Protocol 41 is allowed in your router/firewall (outbound to `server_ipv4`).
2. Check that your public IPv4 matches what HE expects — use `Update Now` in the HE panel or enable `update_enabled`.
3. Ping the server IPv6 from the add-on logs perspective — check for MTU issues by reducing `tunnel_mtu` to `1460` or lower.

### MTU / fragmentation issues

If large packets are dropped, reduce `tunnel_mtu`. A value of `1452` accounts for PPPoE overhead in addition to the IPv4 header.

### "Protocol 41 blocked"

Some ISPs block Protocol 41. Contact your ISP or consider using HE's AYIYA or TSP alternatives (not supported by this add-on).

## Support

- [Open an issue on GitHub](https://github.com/dion-k/ha-tunnelbroker/issues)
- [Hurricane Electric Tunnelbroker forums](https://forums.he.net/)

## License

MIT License — see [LICENSE](LICENSE) for details.

[releases-shield]: https://img.shields.io/github/release/dion-k/ha-tunnelbroker.svg
[releases]: https://github.com/dion-k/ha-tunnelbroker/releases
[license-shield]: https://img.shields.io/github/license/dion-k/ha-tunnelbroker.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg