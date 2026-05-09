#!/usr/bin/env bash
#
# setup-tmux.sh
# Install TPM (Tmux Plugin Manager) at the XDG path, auto-install plugins,
# and clean up the legacy ~/.tmux.conf placeholder if it's empty.
# tmux.conf itself is deployed by setup-dotfiles.sh.

set -e

# Load common library for print_* helpers
# shellcheck source=../lib/common.sh
source "$(dirname "$0")/../lib/common.sh"

print_step "Setting up tmux + TPM..."

# Honor XDG_CONFIG_HOME, default to ~/.config (matches XDG spec)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TMUX_DIR="$XDG_CONFIG_HOME/tmux"
TPM_DIR="$TMUX_DIR/plugins/tpm"

# Bail early if tmux isn't installed (Brewfile install runs before this)
if ! command_exists tmux; then
    print_warning "tmux not found on PATH — skipping TPM setup. Install via: brew install tmux"
    exit 0
fi

# Remove legacy ~/.tmux.conf if it's empty or whitespace-only.
# tmux searches ~/.tmux.conf BEFORE $XDG_CONFIG_HOME/tmux/tmux.conf, so even a
# whitespace-only placeholder there silently shadows the XDG config.
if [[ -f "$HOME/.tmux.conf" ]]; then
    # `grep -v '^[[:space:]]*$'` strips blank/whitespace lines; if nothing remains, the file is effectively empty.
    if [[ -z "$(grep -v '^[[:space:]]*$' "$HOME/.tmux.conf" 2>/dev/null)" ]]; then
        rm "$HOME/.tmux.conf"
        print_info "Removed effectively-empty legacy ~/.tmux.conf (XDG path takes over)"
    else
        print_warning "$HOME/.tmux.conf has content — leaving in place; it will shadow $TMUX_DIR/tmux.conf"
    fi
fi

# Install TPM idempotently. Don't wrap in `timeout` — git has its own connect/idle
# timeouts and the wrapper hid stderr from the user when something went wrong.
if [[ ! -d "$TPM_DIR" ]]; then
    mkdir -p "$(dirname "$TPM_DIR")"
    if git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
        print_success "TPM installed at $TPM_DIR"
    else
        print_warning "TPM clone failed. Retry manually: git clone https://github.com/tmux-plugins/tpm $TPM_DIR"
        exit 0
    fi
else
    print_info "TPM already present at $TPM_DIR"
fi

# Auto-install plugins declared in tmux.conf. TPM's install_plugins reads
# TMUX_PLUGIN_MANAGER_PATH from a running tmux server's environment. A bare
# `start-server` exits the moment it has no clients, so we spin up a detached
# session on a dedicated socket (the env-var must be set BEFORE new-session so
# tmux captures it into the server environment), run the installer, then tear
# down the server. Non-fatal — user can always run prefix+I.
if [[ -f "$TMUX_DIR/tmux.conf" ]]; then
    SOCKET="setup-tmux-bootstrap"
    cleanup_socket() { tmux -L "$SOCKET" kill-server 2>/dev/null || true; }
    trap cleanup_socket EXIT INT TERM

    cleanup_socket  # clear any leftover from a prior failed run
    if TMUX_PLUGIN_MANAGER_PATH="$TMUX_DIR/plugins/" \
        tmux -L "$SOCKET" -f "$TMUX_DIR/tmux.conf" new-session -d -s bootstrap 2>/dev/null \
        && tmux -L "$SOCKET" run-shell "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1; then
        print_success "TPM plugins installed"
    else
        print_warning "TPM plugin install skipped/failed — run prefix+I inside tmux to retry"
    fi

    cleanup_socket
    trap - EXIT INT TERM
else
    print_warning "$TMUX_DIR/tmux.conf not found — skipping plugin install (run setup-dotfiles.sh first)"
fi

print_success "tmux setup complete"
