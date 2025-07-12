# Neovim Configuration

This directory contains the Neovim configuration for the development environment setup.

## Features

- **Modern Lua-based configuration** for better performance and maintainability
- **Sensible defaults** for development work
- **Key mappings** optimized for productivity
- **Auto-commands** for common tasks like removing trailing whitespace
- **Terminal integration** with easy access and navigation

## Key Mappings

### Leader Key
- Leader key is set to `<Space>`

### Window Navigation
- `<C-h>` - Move to left window
- `<C-j>` - Move to lower window
- `<C-k>` - Move to upper window
- `<C-l>` - Move to right window

### File and Buffer Management
- `<leader>e` - Open file explorer
- `<leader>bn` - Next buffer
- `<leader>bp` - Previous buffer
- `<leader>bd` - Delete buffer

### Window Management
- `<leader>sv` - Split window vertically
- `<leader>sh` - Split window horizontally
- `<leader>sc` - Close window

### Terminal
- `<leader>t` - Open terminal
- `<Esc>` - Exit terminal mode

### Text Editing
- `<` and `>` in visual mode - Stay in indent mode
- `J` and `K` in visual mode - Move text up/down
- `<Esc>` - Clear search highlights

## Configuration Structure

- `init.lua` - Main configuration file containing all settings and key mappings

## Customization

You can customize this configuration by:

1. **Editing `init.lua`** directly for basic changes
2. **Adding new Lua files** in the `~/.config/nvim/lua/` directory for more complex configurations
3. **Installing plugins** using a plugin manager like lazy.nvim or packer.nvim

## Backup

The setup script automatically backs up any existing Neovim configuration before installing this one.

## Troubleshooting

If you encounter issues:

1. Check that Neovim is properly installed: `nvim --version`
2. Verify the configuration loads: `nvim --headless -c 'echo "Config loaded"' -c 'qall!'`
3. Look for error messages when starting Neovim
4. Check the backup directory for your previous configuration

## Further Reading

- [Neovim Documentation](https://neovim.io/doc/)
- [Lua in Neovim](https://neovim.io/doc/user/lua.html)
- [Neovim Plugin Ecosystem](https://github.com/rockerBOO/awesome-neovim)
