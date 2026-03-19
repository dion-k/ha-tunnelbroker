# Changelog

## [1.2.0] - 2026-03-19

### Fixed
- Fixed container startup failure (s6-overlay compatibility issue)
- Container now runs without s6-overlay for maximum compatibility

## [1.1.2] - 2026-03-19

### Fixed
- s6-overlay service integration: moved run script to `/etc/services.d/he-tunnelbroker/run` so s6-overlay can start the service correctly
- Removed `init: false` from `config.yaml` to allow s6-overlay to manage service lifecycle
- Removed `CMD` from Dockerfile in favour of s6-overlay service directory
- Added `finish.sh` for clean tunnel teardown on service stop

## [1.1.0] - 2026-03-18

### Added
- Add-on icon and logo
- Startup retry mechanism (3 attempts before entering recovery loop)
- Tunnel traffic statistics logging on each health check
- Optional Home Assistant notification on successful tunnel start
- Improved DOCS.md with quick start guide and troubleshooting

### Changed
- Improved documentation with configuration table and troubleshooting section

## [1.0.0] - 2026-03-18

### Added

- Initial release of the HE Tunnelbroker (6in4) add-on
- Creates a SIT (Protocol 41) tunnel to Hurricane Electric Tunnelbroker
- Auto-detection of public IPv4 address (`client_ipv4: "auto"`)
- Automatic IPv4 endpoint updates via the HE Tunnelbroker API
- Configurable MTU, DNS servers, and update interval
- Graceful shutdown with tunnel cleanup on SIGTERM/SIGINT
- Periodic IPv6 connectivity health checks with automatic tunnel restart on failure
- Configurable health-check host (`healthcheck_host`) and interval (`healthcheck_interval`)
- Input validation on startup — fatal error if required fields are empty or contain placeholder values
- `SYS_MODULE` privilege for reliable `modprobe sit` support
- Schema range constraints for `tunnel_mtu` (1280–1480) and `update_interval` / `healthcheck_interval` (60–3600)
- MIT LICENSE file
- Support for all Home Assistant architectures: armhf, armv7, aarch64, amd64, i386
