#!/bin/bash

# This script handles applications that need special setup

echo "Setting up applications..."

# Claude CLI global installation
if command -v npm &> /dev/null; then
    npm install -g @anthropic-ai/claude-code
    echo "Claude CLI installed. Run 'claude setup-token' to authenticate."
fi

# VS Code extensions
if command -v code &> /dev/null && [ -f vscode/extensions.txt ]; then
    echo "Installing VS Code extensions..."
    while read -r extension; do
        code --install-extension "$extension"
    done < vscode/extensions.txt
fi

echo "Application setup complete!"
echo ""
echo "Manual steps required:"
echo "1. Open VS Code and configure settings from vscode/settings.json"
echo "2. Authenticate Claude CLI: claude setup-token"
echo "3. Configure any remaining applications manually"
