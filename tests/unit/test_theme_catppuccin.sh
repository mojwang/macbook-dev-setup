#!/usr/bin/env bash

# Catppuccin Mocha is no longer the active theme — Solarized Dark replaced
# it across nvim/tmux/bat/fzf (see test_theme_solarized.sh). The Mocha YAML
# is intentionally preserved in dotfiles/.warp/themes/ as a one-click Warp
# fallback (Settings → Appearance → Themes), so this test guards that the
# fallback YAML stays well-formed and palette-correct.

source "$(dirname "$0")/../test_framework.sh"

if [[ -f "$ROOT_DIR/lib/common.sh" ]]; then
    # shellcheck source=/dev/null
    source "$ROOT_DIR/lib/common.sh"
fi

describe "Catppuccin Mocha Warp Theme (Fallback)"

WARP_THEME="$ROOT_DIR/dotfiles/.warp/themes/catppuccin_mocha.yml"

it "should preserve Catppuccin Mocha Warp YAML as a one-click fallback"
assert_file_exists "$WARP_THEME" "Mocha YAML should remain deployed for fallback selection"
assert_file_contains "$WARP_THEME" "name: 'Catppuccin Mocha'" "YAML must declare name (required by Warp)"
assert_file_contains "$WARP_THEME" "background: '#1e1e2e'" "background should be Mocha base"
assert_file_contains "$WARP_THEME" "foreground: '#cdd6f4'" "foreground should be Mocha text"

summarize
