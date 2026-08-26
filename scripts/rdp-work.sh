#!/usr/bin/env bash
# Launch an RDP session to the ULMS Windows server.
#
# Reads config.env (this repo, or ~/.config/ulms-rdp/config.env), pulls the
# password from the GNOME keyring, and hands off to FreeRDP. Checks the things
# that commonly go wrong first, so failures say what is actually broken.
set -euo pipefail

die() { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '\033[36m→\033[0m %s\n' "$1"; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- configuration ---------------------------------------------------------
for candidate in "$REPO_ROOT/config.env" "$HOME/.config/ulms-rdp/config.env"; do
    if [[ -f "$candidate" ]]; then CONFIG="$candidate"; break; fi
done

[[ -n "${CONFIG:-}" ]] || die "no config.env found.
  Run: cp '$REPO_ROOT/config.env.example' '$REPO_ROOT/config.env' && chmod 600 '$REPO_ROOT/config.env'
  then edit it."

# shellcheck disable=SC1090
set -a; source "$CONFIG"; set +a

: "${RDP_HOST:?RDP_HOST is not set in $CONFIG}"
: "${RDP_USER:?RDP_USER is not set in $CONFIG}"
RDP_SHARE_DIR="${RDP_SHARE_DIR:-$HOME/rdp_share}"
RDP_SHARE_NAME="${RDP_SHARE_NAME:-share}"
RDP_BIN="${RDP_BIN:-xfreerdp}"

[[ "$RDP_HOST" == "10.x.x.x" || "$RDP_USER" == "your_windows_username" ]] &&
    die "$CONFIG still has the example placeholders in it."

# --- preflight -------------------------------------------------------------
command -v "$RDP_BIN" >/dev/null 2>&1 ||
    die "'$RDP_BIN' not found. Install it (sudo apt install -y freerdp2-x11), or set RDP_BIN in $CONFIG."

mkdir -p "$RDP_SHARE_DIR"

if command -v nc >/dev/null 2>&1; then
    nc -z -w 4 "$RDP_HOST" 3389 2>/dev/null ||
        die "cannot reach $RDP_HOST on port 3389. Is the VPN connected?"
fi

# --- password --------------------------------------------------------------
if grep -qi microsoft /proc/version 2>/dev/null && [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    info "WSL2 detected with no D-Bus session; starting one."
    eval "$(dbus-launch --sh-syntax)"
fi

PASSWORD="$(secret-tool lookup rdp "$RDP_HOST" 2>/dev/null || true)"
[[ -n "$PASSWORD" ]] || die "no keyring entry for '$RDP_HOST'.
  Store one with: secret-tool store --label=\"ULMS RDP Password\" rdp $RDP_HOST"

# --- build the command -----------------------------------------------------
args=(
    "/v:$RDP_HOST"
    "/u:$RDP_USER"
    /dynamic-resolution
    +clipboard
    /cert:ignore
    "/drive:$RDP_SHARE_NAME,$RDP_SHARE_DIR"
)
[[ -n "${RDP_DOMAIN:-}" ]] && args+=("/d:$RDP_DOMAIN")
[[ -n "${RDP_SCALE:-}" ]] && args+=("/scale:$RDP_SCALE" "/scale-desktop:$RDP_SCALE" "/scale-device:$RDP_SCALE")
# shellcheck disable=SC2206
[[ -n "${RDP_EXTRA_FLAGS:-}" ]] && args+=(${RDP_EXTRA_FLAGS})

info "Connecting to $RDP_HOST as $RDP_USER (share: $RDP_SHARE_DIR -> \\\\tsclient\\$RDP_SHARE_NAME)"

# Prefer feeding the password on stdin so it never appears in `ps aux`.
# Older or trimmed builds lack /from-stdin, in which case fall back to /p:.
if "$RDP_BIN" /help 2>&1 | grep -q -- '--from-stdin\|/from-stdin'; then
    exec "$RDP_BIN" "${args[@]}" /from-stdin <<<"$PASSWORD"
else
    info "this build has no /from-stdin; passing the password on the command line."
    exec "$RDP_BIN" "${args[@]}" "/p:$PASSWORD"
fi
