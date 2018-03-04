#!/bin/sh

# =============================================================================
#
# DDNS update script.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Update DDNS record Periodically.
# -----------------------------------------------------------------------------
USERNAME=
PASSWORD=
DOMAIN=sjh-vps.imwork.net

while true
do
    /usr/bin/curl "http://${USERNAME}:${PASSWORD}@ddns.oray.com/ph/update?hostname=${DOMAIN}"

    sleep 15m
done
