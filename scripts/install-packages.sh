#!/bin/bash

# Install packages from Brewfile
brew bundle --file=homebrew/Brewfile

# Update all packages
brew update
brew upgrade

# Cleanup
brew cleanup
