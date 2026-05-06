#!/usr/bin/env bash
# Personal configuration for macbook-dev-setup
# Copy this directory to .personal/ and fill in your values:
#   cp -r .personal.example .personal
#   edit .personal/config.sh
#
# Or run: ./scripts/setup-claude-agentic.sh (wizard creates this for you)
#
# This file is sourced by scripts — use bash variable syntax.

# Your GitHub username (used for clone URLs, PR reviewer, scaffold)
GITHUB_USER="your-username"

# PR reviewer assignment (defaults to GITHUB_USER if empty)
REVIEWER=""

# Second brain workspace path (optional — skip if not using a workspace)
# All repos managed by this framework should live under $SECOND_BRAIN_HOME/repos/
SECOND_BRAIN_HOME=""

# Second brain repo to clone (optional — "user/repo" format)
# Only used during scaffold when creating a new workspace
SECOND_BRAIN_REPO=""
