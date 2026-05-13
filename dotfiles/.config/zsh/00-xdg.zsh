# XDG Base Directory defaults
# Most tools fall back to ~/.config when XDG_CONFIG_HOME is unset, but exporting
# it explicitly helps tools that don't have a built-in fallback (rare but real)
# and makes the convention discoverable to anyone reading the shell environment.

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
