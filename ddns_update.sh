#!/bin/sh

# =============================================================================
#
# DDNS update script.
#
# =============================================================================

# -----------------------------------------------------------------------------
# Update DDNS record Periodically.
# -----------------------------------------------------------------------------
USERNAME=qq329889612
PASSWORD=Sjh890114
DOMAIN=sjh-vps.imwork.net

/usr/bin/curl "http://${USERNAME}:${PASSWORD}@ddns.oray.com/ph/update?hostname=${DOMAIN}"

sleep 1d
