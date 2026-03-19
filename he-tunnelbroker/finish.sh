#!/usr/bin/with-bashio
# shellcheck shell=bash

# Clean up tunnel on service stop
bashio::log.info "Cleaning up tunnel..."
ip tunnel del he-ipv6 2>/dev/null || true
bashio::log.info "Tunnel removed."
