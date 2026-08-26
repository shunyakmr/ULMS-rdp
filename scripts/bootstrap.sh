#!/usr/bin/env bash
# One-shot setup: installs prerequisites, creates the shared folder, and walks
# through storing the password. Safe to re-run.
set -euo pipefail

info() { printf '\033[36m→\033[0m %s\n' "$1"; }
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info "Installing FreeRDP, secret-tool and gnome-keyring…"
sudo apt update
if apt-cache show freerdp2-x11 >/dev/null 2>&1; then
    sudo apt install -y freerdp2-x11 libsecret-tools gnome-keyring
else
    info "freerdp2-x11 unavailable on this release; installing freerdp3-x11."
    sudo apt install -y freerdp3-x11 libsecret-tools gnome-keyring
fi

info "Creating the shared folder…"
mkdir -p "$HOME/rdp_share"

if [[ ! -f "$REPO_ROOT/config.env" ]]; then
    install -m 600 "$REPO_ROOT/config.env.example" "$REPO_ROOT/config.env"
    info "Created config.env — edit it now, then re-run this script."
    exit 0
fi

set -a; source "$REPO_ROOT/config.env"; set +a
if [[ "${RDP_HOST:-}" == "10.x.x.x" || -z "${RDP_HOST:-}" ]]; then
    info "config.env still has placeholders. Edit it, then re-run."
    exit 1
fi

if grep -qi microsoft /proc/version 2>/dev/null && [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    info "WSL2 detected; starting a D-Bus session."
    eval "$(dbus-launch --sh-syntax)"
fi

if secret-tool lookup rdp "$RDP_HOST" >/dev/null 2>&1; then
    info "Keyring entry for $RDP_HOST already exists — leaving it alone."
else
    info "Enter your Windows password (input is hidden, nothing is echoed):"
    secret-tool store --label="ULMS RDP Password" rdp "$RDP_HOST"
fi

chmod +x "$REPO_ROOT/scripts/rdp-work.sh"
info "Done. Add this to ~/.bashrc, then 'source ~/.bashrc':"
printf "\n    alias rdp-work='%s/scripts/rdp-work.sh'\n\n" "$REPO_ROOT"
