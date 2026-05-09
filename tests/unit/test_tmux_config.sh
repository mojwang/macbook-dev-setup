#!/usr/bin/env bash

# Tests for tmux + TPM baseline configuration

source "$(dirname "$0")/../test_framework.sh"

if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Tmux Configuration Tests"

TMUX_CONF="$ROOT_DIR/dotfiles/.config/tmux/tmux.conf"
SETUP_SCRIPT="$ROOT_DIR/scripts/setup-tmux.sh"

# ─── repo-state assertions ──────────────────────────────────────────
it "should ship a tmux.conf at the XDG path inside dotfiles/"
assert_file_exists "$TMUX_CONF" "tmux.conf should exist at dotfiles/.config/tmux/tmux.conf"

it "should ship setup-tmux.sh installer"
assert_file_exists "$SETUP_SCRIPT" "setup-tmux.sh should exist"
assert_true "[[ -x '$SETUP_SCRIPT' ]]" "setup-tmux.sh should be executable"

it "should declare the rebound prefix"
assert_file_contains "$TMUX_CONF" "set -g prefix C-Space" "C-Space prefix should be set"
assert_file_contains "$TMUX_CONF" "unbind C-b" "default C-b prefix should be unbound"

it "should enable vi-mode and modern QoL defaults"
assert_file_contains "$TMUX_CONF" "mode-keys vi" "vi copy-mode should be enabled"
assert_file_contains "$TMUX_CONF" "set -g mouse on" "mouse mode should be enabled"
assert_file_contains "$TMUX_CONF" "renumber-windows on" "renumber-windows should be on"
assert_file_contains "$TMUX_CONF" "focus-events on" "focus-events should be on (nvim integration)"
assert_file_contains "$TMUX_CONF" "base-index 1" "base-index should start at 1"

it "should declare vim-aware seamless pane navigation"
assert_file_contains "$TMUX_CONF" 'is_vim=' "should define is_vim shell predicate"
assert_file_contains "$TMUX_CONF" "if-shell \"\$is_vim\" 'send-keys C-h' 'select-pane -L'" "C-h should passthrough or select-pane left"
assert_file_contains "$TMUX_CONF" "if-shell \"\$is_vim\" 'send-keys C-l' 'select-pane -R'" "C-l should passthrough or select-pane right"
assert_file_contains "$TMUX_CONF" "bind C-l send-keys 'C-l'" "prefix+C-l should restore literal clear-screen"

it "should enumerate the baseline TPM plugins"
assert_file_contains "$TMUX_CONF" "tmux-plugins/tpm" "tpm plugin manager should be declared"
assert_file_contains "$TMUX_CONF" "tmux-plugins/tmux-sensible" "tmux-sensible should be declared"
assert_file_contains "$TMUX_CONF" "tmux-plugins/tmux-yank" "tmux-yank should be declared"
assert_file_contains "$TMUX_CONF" "tmux-plugins/tmux-resurrect" "tmux-resurrect should be declared"
assert_file_contains "$TMUX_CONF" "tmux-plugins/tmux-continuum" "tmux-continuum should be declared"

it "should initialize TPM at the XDG plugin path"
assert_file_contains "$TMUX_CONF" '~/.config/tmux/plugins/tpm/tpm' "TPM init line should reference XDG plugins path"
assert_file_contains "$TMUX_CONF" '~/.config/tmux/tmux.conf' "reload binding should source XDG config path"

# ─── installer-script assertions ────────────────────────────────────
it "should clone TPM into the XDG plugins dir"
assert_file_contains "$SETUP_SCRIPT" "tmux-plugins/tpm" "installer should clone tmux-plugins/tpm"
assert_file_contains "$SETUP_SCRIPT" "XDG_CONFIG_HOME" "installer should use XDG_CONFIG_HOME"
assert_file_contains "$SETUP_SCRIPT" "install_plugins" "installer should run TPM's install_plugins"

it "should remove an effectively-empty legacy ~/.tmux.conf placeholder"
assert_file_contains "$SETUP_SCRIPT" 'rm "$HOME/.tmux.conf"' "installer should rm legacy placeholder"
assert_file_contains "$SETUP_SCRIPT" '[[:space:]]' "installer should guard rm with a whitespace-only check"

# ─── orchestration assertions ───────────────────────────────────────
it "should be wired into setup.sh after setup-dotfiles.sh"
setup_content=$(cat "$ROOT_DIR/setup.sh")
assert_contains "$setup_content" "setup-tmux.sh" "setup.sh should invoke setup-tmux.sh"

# tmux setup must run AFTER dotfiles so tmux.conf exists when TPM auto-installs plugins
dotfiles_line=$(grep -n "scripts/setup-dotfiles.sh$" "$ROOT_DIR/setup.sh" | head -1 | cut -d: -f1)
tmux_line=$(grep -n "scripts/setup-tmux.sh" "$ROOT_DIR/setup.sh" | head -1 | cut -d: -f1)
assert_true "[[ $tmux_line -gt $dotfiles_line ]]" "tmux setup should be ordered after dotfiles setup"

it "should be wired into setup-dotfiles.sh for config deployment"
dotfiles_content=$(cat "$ROOT_DIR/scripts/setup-dotfiles.sh")
assert_contains "$dotfiles_content" "dotfiles/.config/tmux/tmux.conf" "setup-dotfiles.sh should reference the tmux config source"
assert_contains "$dotfiles_content" ".config/tmux/tmux.conf" "setup-dotfiles.sh should target the XDG destination"

# ─── runtime syntax check (only when tmux binary is present) ────────
it "should parse without tmux syntax errors when tmux is installed"
if command -v tmux >/dev/null 2>&1; then
    # tmux exits a server with no clients, so we spin up a detached session on
    # a unique socket, then check the server's running state. Any parse errors
    # surface as messages in the server log via display-message; we capture
    # them via show-messages.
    _SOCK="test-tmux-config-check-$$"
    tmux -L "$_SOCK" kill-server 2>/dev/null || true
    parse_stderr=$(tmux -L "$_SOCK" -f "$TMUX_CONF" new-session -d -s parsecheck 2>&1)
    tmux -L "$_SOCK" kill-server 2>/dev/null || true
    # tmux prints config errors to stderr at server start; treat any non-empty,
    # non-warning-only output as a failure.
    parse_errors=$(echo "$parse_stderr" | grep -iE "error|unknown variable|invalid" || true)
    assert_empty "$parse_errors" "tmux should parse the config without errors"
else
    echo "  (tmux not installed — skipping live parse check)"
fi

it "should ship 00-xdg.zsh exporting XDG_CONFIG_HOME"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/00-xdg.zsh" "00-xdg.zsh module should exist"
assert_file_contains "$ROOT_DIR/dotfiles/.config/zsh/00-xdg.zsh" 'XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"' \
    "00-xdg.zsh should export XDG_CONFIG_HOME with default"

# ─── nvim ↔ tmux integration ────────────────────────────────────────
NVIM_INIT="$ROOT_DIR/dotfiles/.config/nvim/init.lua"

it "should ship a smart vim↔tmux navigator in init.lua"
assert_file_exists "$NVIM_INIT" "nvim init.lua should exist"
assert_file_contains "$NVIM_INIT" "function smart_nav" "init.lua should define smart_nav helper"
assert_file_contains "$NVIM_INIT" 'vim.env.TMUX' "smart_nav should detect tmux via vim.env.TMUX"
assert_file_contains "$NVIM_INIT" '"tmux", "select-pane"' "smart_nav should shell out to tmux select-pane"

it "should bind C-h/j/k/l to smart_nav rather than plain wincmd"
assert_file_contains "$NVIM_INIT" 'smart_nav("h", "L")' "C-h should call smart_nav for left"
assert_file_contains "$NVIM_INIT" 'smart_nav("j", "D")' "C-j should call smart_nav for down"
assert_file_contains "$NVIM_INIT" 'smart_nav("k", "U")' "C-k should call smart_nav for up"
assert_file_contains "$NVIM_INIT" 'smart_nav("l", "R")' "C-l should call smart_nav for right"

it "should enable OSC 52 clipboard via unnamedplus"
assert_file_contains "$NVIM_INIT" 'vim.opt.clipboard = "unnamedplus"' "clipboard should be unnamedplus"

it "should load without errors when nvim is installed"
if command -v nvim >/dev/null 2>&1; then
    nvim_load_errors=$(nvim --headless -u "$NVIM_INIT" -c 'qa!' 2>&1 | grep -iE "error|E[0-9]+" || true)
    assert_empty "$nvim_load_errors" "nvim should load init.lua without errors"
else
    echo "  (nvim not installed — skipping live load check)"
fi

summarize
