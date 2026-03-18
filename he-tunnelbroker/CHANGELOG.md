# Changelog

## [1.0.0] - 2026-03-18

### Added

- Initial release of the HE Tunnelbroker (6in4) add-on
- Creates a SIT (Protocol 41) tunnel to Hurricane Electric Tunnelbroker
- Auto-detection of public IPv4 address (`client_ipv4: "auto"`)
- Automatic IPv4 endpoint updates via the HE Tunnelbroker API
- Configurable MTU, DNS servers, and update interval
- Graceful shutdown with tunnel cleanup on SIGTERM/SIGINT
- Periodic IPv6 connectivity health checks
- Support for all Home Assistant architectures: armhf, armv7, aarch64, amd64, i386
