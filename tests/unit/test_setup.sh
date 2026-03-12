#!/usr/bin/env bash

# Repo inventory tests — verify required project files and directories exist
# Source test framework
source "$(dirname "$0")/../test_framework.sh"

describe "Repo Inventory: Core Files"

it "should have setup.sh entry point"
assert_file_exists "$ROOT_DIR/setup.sh" "setup.sh should exist"

it "should have Brewfile.minimal for minimal installs"
assert_file_exists "$ROOT_DIR/homebrew/Brewfile.minimal" "Brewfile.minimal should exist"

it "should have npm global packages list"
assert_file_exists "$ROOT_DIR/nodejs-config/global-packages.txt" "Global packages list exists"

it "should have Python requirements file"
assert_file_exists "$ROOT_DIR/python/requirements.txt" "Python requirements exists"

describe "Repo Inventory: Zsh Modules"

it "should have modular zsh configuration directory"
assert_directory_exists "$ROOT_DIR/dotfiles/.config/zsh" "Zsh config directory should exist"

it "should have all required zsh modules"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/00-homebrew.zsh" "Homebrew module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/10-languages.zsh" "Languages module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/20-tools.zsh" "Tools module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/30-aliases.zsh" "Aliases module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/40-functions.zsh" "Functions module should exist"
assert_file_exists "$ROOT_DIR/dotfiles/.config/zsh/50-environment.zsh" "Environment module should exist"
# Note: 99-local.zsh is gitignored and created by users, so we don't test for it

it "should have modular zshrc loader"
assert_file_exists "$ROOT_DIR/dotfiles/.zshrc" "Main .zshrc should exist"

describe "Repo Inventory: Starship Config"

it "should have starship prompt configuration"
assert_file_exists "$ROOT_DIR/dotfiles/.config/starship.toml" "Starship config should exist"
