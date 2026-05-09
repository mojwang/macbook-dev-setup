#!/usr/bin/env bash

# Tests for the Catppuccin Mocha coordinated theme across Warp / tmux / nvim
# / bat / fzf. Asserts on the repo source-of-truth files and (when the live
# tool is present) verifies the deployed config picks the correct palette.

source "$(dirname "$0")/../test_framework.sh"

if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Catppuccin Mocha Coordinated Theme"

WARP_THEME="$ROOT_DIR/dotfiles/.warp/themes/catppuccin_mocha.yml"
TMUX_CONF="$ROOT_DIR/dotfiles/.config/tmux/tmux.conf"
NVIM_INIT="$ROOT_DIR/dotfiles/.config/nvim/init.lua"
ZSH_TOOLS="$ROOT_DIR/dotfiles/.config/zsh/20-tools.zsh"
DOTFILES_SETUP="$ROOT_DIR/scripts/setup-dotfiles.sh"

# ─── Warp theme ─────────────────────────────────────────────────────
it "should ship Warp catppuccin_mocha theme YAML"
assert_file_exists "$WARP_THEME" "Warp Catppuccin Mocha YAML should exist"
assert_file_contains "$WARP_THEME" "background: '#1e1e2e'" "background should be Mocha base"
assert_file_contains "$WARP_THEME" "foreground: '#cdd6f4'" "foreground should be Mocha text"

it "should deploy Warp themes + flip active theme via setup-dotfiles.sh"
assert_file_contains "$DOTFILES_SETUP" 'dotfiles/.warp/themes' "setup-dotfiles.sh should reference Warp themes source"
assert_file_contains "$DOTFILES_SETUP" 'theme = "catppuccin_mocha"' "setup-dotfiles.sh should set the active theme"

# ─── tmux ────────────────────────────────────────────────────────────
it "should declare catppuccin/tmux plugin and Mocha flavor"
assert_file_contains "$TMUX_CONF" "@plugin 'catppuccin/tmux" "catppuccin/tmux plugin should be declared"
assert_file_contains "$TMUX_CONF" "@catppuccin_flavor 'mocha'" "tmux flavor should be mocha"
assert_file_contains "$TMUX_CONF" "@catppuccin_status_session" "status-left should embed catppuccin session module"

# ─── nvim ────────────────────────────────────────────────────────────
it "should install catppuccin via vim.pack and apply mocha"
assert_file_contains "$NVIM_INIT" "vim.pack.add" "init.lua should use vim.pack.add"
assert_file_contains "$NVIM_INIT" "https://github.com/catppuccin/nvim" "init.lua should reference catppuccin/nvim"
assert_file_contains "$NVIM_INIT" 'flavour = "mocha"' "catppuccin.setup should pick mocha flavour"
assert_file_contains "$NVIM_INIT" 'colorscheme, "catppuccin-mocha"' "should set catppuccin-mocha colorscheme"

it "should apply catppuccin-mocha when nvim loads"
if command -v nvim >/dev/null 2>&1 && find "$HOME/.local/share/nvim/site/pack" -maxdepth 4 -type d -name "catppuccin*" 2>/dev/null | grep -q .; then
    # Prefix-tag the report so we can grep past init.lua's load-success print()
    scheme=$(nvim --headless -c 'lua print("CSCHEME:" .. tostring(vim.g.colors_name))' -c 'qa!' 2>&1 | grep -E '^CSCHEME:' | head -1)
    assert_contains "$scheme" "catppuccin-mocha" "live nvim should report catppuccin-mocha colorscheme"
else
    echo "  (catppuccin not yet installed via vim.pack — skipping live colorscheme check)"
fi

# ─── bat + fzf ───────────────────────────────────────────────────────
it "should set BAT_THEME to Catppuccin Mocha"
assert_file_contains "$ZSH_TOOLS" 'BAT_THEME="Catppuccin Mocha"' "bat theme should be Catppuccin Mocha"

it "should override FZF_DEFAULT_OPTS with the Mocha palette"
assert_file_contains "$ZSH_TOOLS" "bg:#1e1e2e" "fzf bg should be Mocha base"
assert_file_contains "$ZSH_TOOLS" "fg:#cdd6f4" "fzf fg should be Mocha text"
assert_file_contains "$ZSH_TOOLS" "hl:#f38ba8" "fzf highlight should be Mocha red/pink"

it "should expose the bat theme name when bat is installed"
if command -v bat >/dev/null 2>&1; then
    bat_themes=$(bat --list-themes 2>/dev/null | grep -F "Catppuccin Mocha" || true)
    assert_not_empty "$bat_themes" "bat should know the Catppuccin Mocha theme"
else
    echo "  (bat not installed — skipping live theme check)"
fi

summarize
