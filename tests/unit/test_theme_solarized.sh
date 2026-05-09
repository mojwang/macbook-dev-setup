#!/usr/bin/env bash

# Tests for the Solarized Dark coordinated theme across Warp / tmux / nvim
# / bat / fzf. Asserts on the repo source-of-truth files and (when the live
# tool is present) verifies the deployed config picks the correct palette.
# Catppuccin Mocha YAML is intentionally preserved as a one-click Warp
# fallback; only the *active* layers (nvim/tmux/bat/fzf) are required to be
# Solarized.

source "$(dirname "$0")/../test_framework.sh"

if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Solarized Dark Coordinated Theme"

WARP_THEME="$ROOT_DIR/dotfiles/.warp/themes/solarized_dark.yml"
TMUX_CONF="$ROOT_DIR/dotfiles/.config/tmux/tmux.conf"
NVIM_INIT="$ROOT_DIR/dotfiles/.config/nvim/init.lua"
ZSH_TOOLS="$ROOT_DIR/dotfiles/.config/zsh/20-tools.zsh"
DOTFILES_SETUP="$ROOT_DIR/scripts/setup-dotfiles.sh"

# ─── Warp theme ─────────────────────────────────────────────────────
it "should ship Warp solarized_dark theme YAML with required fields"
assert_file_exists "$WARP_THEME" "Warp Solarized Dark YAML should exist"
assert_file_contains "$WARP_THEME" "name: 'Solarized Dark'" "YAML must declare name (required by Warp)"
assert_file_contains "$WARP_THEME" "background: '#002b36'" "background should be Solarized base03"
assert_file_contains "$WARP_THEME" "foreground: '#839496'" "foreground should be Solarized base0"
assert_file_contains "$WARP_THEME" "accent: '#268bd2'" "accent should be Solarized blue"

it "should deploy Warp themes via setup-dotfiles.sh (UI selection required)"
assert_file_contains "$DOTFILES_SETUP" 'dotfiles/.warp/themes' "setup-dotfiles.sh should reference Warp themes source"
assert_file_contains "$DOTFILES_SETUP" "Settings → Appearance → Themes" "should instruct user to pick theme via Warp UI"

# ─── tmux ────────────────────────────────────────────────────────────
it "should hand-roll Solarized Dark status line (no catppuccin/tmux plugin)"
assert_file_contains "$TMUX_CONF" "bg=#073642,fg=#839496" "status-style should use Solarized base02 bg + base0 fg"
assert_file_contains "$TMUX_CONF" "bg=#268bd2" "session/host accent should be Solarized blue"
assert_file_contains "$TMUX_CONF" "bg=#b58900" "current-window highlight should be Solarized yellow"
assert_file_contains "$TMUX_CONF" "pane-active-border-style 'fg=#268bd2'" "active pane border should be Solarized blue"
tmux_conf_content=$(cat "$TMUX_CONF")
assert_not_contains "$tmux_conf_content" "@plugin 'catppuccin/tmux" "catppuccin/tmux plugin should be removed"
assert_not_contains "$tmux_conf_content" "@catppuccin_flavor" "catppuccin flavor variable should be removed"

# ─── nvim ────────────────────────────────────────────────────────────
it "should install solarized.nvim via vim.pack and apply dark variant"
assert_file_contains "$NVIM_INIT" "vim.pack.add" "init.lua should use vim.pack.add"
assert_file_contains "$NVIM_INIT" "https://github.com/maxmx03/solarized.nvim" "init.lua should reference maxmx03/solarized.nvim"
assert_file_contains "$NVIM_INIT" 'vim.o.background = "dark"' "should set background to dark before colorscheme"
assert_file_contains "$NVIM_INIT" 'colorscheme, "solarized"' "should set solarized colorscheme"
nvim_init_content=$(cat "$NVIM_INIT")
assert_not_contains "$nvim_init_content" "catppuccin/nvim" "old catppuccin plugin reference should be gone"
assert_not_contains "$nvim_init_content" "catppuccin-mocha" "old catppuccin-mocha colorscheme reference should be gone"

it "should apply solarized when nvim loads"
if command -v nvim >/dev/null 2>&1 && find "$HOME/.local/share/nvim/site/pack" -maxdepth 4 -type d -iname "solarized*" 2>/dev/null | grep -q .; then
    # Prefix-tag the report so we can grep past init.lua's load-success print()
    scheme=$(nvim --headless -c 'lua print("CSCHEME:" .. tostring(vim.g.colors_name))' -c 'qa!' 2>&1 | grep -E '^CSCHEME:' | head -1)
    assert_contains "$scheme" "solarized" "live nvim should report solarized colorscheme"
else
    echo "  (solarized.nvim not yet installed via vim.pack — skipping live colorscheme check)"
fi

# ─── bat + fzf ───────────────────────────────────────────────────────
it "should set BAT_THEME to Solarized (dark)"
assert_file_contains "$ZSH_TOOLS" 'BAT_THEME="Solarized (dark)"' "bat theme should be Solarized (dark)"

it "should override FZF_DEFAULT_OPTS with the Solarized Dark palette"
assert_file_contains "$ZSH_TOOLS" "bg:#002b36" "fzf bg should be Solarized base03"
assert_file_contains "$ZSH_TOOLS" "fg:#839496" "fzf fg should be Solarized base0"
assert_file_contains "$ZSH_TOOLS" "hl:#b58900" "fzf highlight should be Solarized yellow"
assert_file_contains "$ZSH_TOOLS" "pointer:#268bd2" "fzf pointer should be Solarized blue"

it "should expose the bat theme name when bat is installed"
if command -v bat >/dev/null 2>&1; then
    bat_themes=$(bat --list-themes 2>/dev/null | grep -F "Solarized (dark)" || true)
    assert_not_empty "$bat_themes" "bat should know the Solarized (dark) theme"
else
    echo "  (bat not installed — skipping live theme check)"
fi

summarize
