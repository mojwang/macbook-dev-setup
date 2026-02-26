#!/usr/bin/env bash
# Agent Decision Tree - Interactive helper to choose the right agent
# Reduces cognitive load from 12 agents to guided decision making

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}  🤖 AGENT DECISION TREE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "I'll help you choose the right agent for your task."
echo ""

# Question 1: What are you trying to do?
echo -e "${YELLOW}1. What are you trying to do?${NC}"
echo ""
echo "  a) Write or modify code"
echo "  b) Test or validate code"
echo "  c) Find security issues"
echo "  d) Improve performance"
echo "  e) Update documentation"
echo "  f) Manage project/tasks"
echo "  g) Other"
echo ""
read -p "Enter choice (a-g): " task_type

case $task_type in
  a)
    echo ""
    echo -e "${YELLOW}2. What kind of code?${NC}"
    echo ""
    echo "  1) Shell scripts (.sh files)"
    echo "  2) Configuration files"
    echo "  3) Application code"
    echo "  4) Infrastructure/DevOps"
    echo ""
    read -p "Enter choice (1-4): " code_type

    case $code_type in
      1)
        echo ""
        echo -e "${GREEN}✨ RECOMMENDED: Shell Script Agent${NC}"
        echo ""
        echo "📝 Why: Specialized for Bash scripts with built-in validation"
        echo ""
        echo "🎯 What it does:"
        echo "  • Validates syntax and best practices"
        echo "  • Adds error handling (set -e, timeouts)"
        echo "  • Ensures signal-safe cleanup"
        echo "  • Runs shellcheck automatically"
        echo ""
        echo "▶️  How to use:"
        echo "   Just ask Claude to write/modify a shell script"
        echo "   The Shell Script Agent will automatically activate"
        echo ""
        ;;
      2)
        echo ""
        echo -e "${GREEN}✨ RECOMMENDED: Configuration Agent${NC}"
        echo ""
        echo "📝 Why: Handles dotfiles, MCP configs, system settings"
        echo ""
        echo "🎯 What it does:"
        echo "  • Validates config syntax"
        echo "  • Checks for conflicts"
        echo "  • Backs up before changes"
        echo "  • Tests configuration validity"
        echo ""
        ;;
      3)
        echo ""
        echo -e "${GREEN}✨ RECOMMENDED: Development Agent${NC}"
        echo ""
        echo "📝 Why: General-purpose code implementation"
        echo ""
        echo "🎯 What it does:"
        echo "  • Implements features"
        echo "  • Follows project patterns"
        echo "  • Writes clean, tested code"
        echo "  • Integrates with existing codebase"
        echo ""
        ;;
      4)
        echo ""
        echo -e "${GREEN}✨ RECOMMENDED: Infrastructure Agent${NC}"
        echo ""
        echo "📝 Why: CI/CD, Docker, deployment scripts"
        echo ""
        echo "🎯 What it does:"
        echo "  • Manages deployment pipelines"
        echo "  • Handles Docker/containerization"
        echo "  • Configures CI/CD"
        echo ""
        ;;
    esac
    ;;

  b)
    echo ""
    echo -e "${GREEN}✨ RECOMMENDED: Quality Agent${NC}"
    echo ""
    echo "📝 Why: Comprehensive testing and validation"
    echo ""
    echo "🎯 What it does:"
    echo "  • Runs unit tests"
    echo "  • Integration testing"
    echo "  • Test coverage analysis"
    echo "  • Identifies edge cases"
    echo ""
    echo "▶️  How to use:"
    echo "   Ask Claude: \"Run quality checks on my recent changes\""
    echo "   Or run tests directly: ${BLUE}./tests/run_tests.sh${NC}"
    echo ""
    ;;

  c)
    echo ""
    echo -e "${GREEN}✨ RECOMMENDED: Security Agent${NC}"
    echo ""
    echo "📝 Why: Find vulnerabilities before they become problems"
    echo ""
    echo "🎯 What it does:"
    echo "  • Scans for security issues (Semgrep)"
    echo "  • Checks for exposed credentials"
    echo "  • Validates input sanitization"
    echo "  • Reviews authentication logic"
    echo ""
    echo "▶️  How to use:"
    echo "   Ask Claude: \"Perform security analysis on my shell scripts\""
    echo "   Semgrep MCP is available for automated scanning"
    echo ""
    ;;

  d)
    echo ""
    echo -e "${GREEN}✨ RECOMMENDED: Performance Agent${NC}"
    echo ""
    echo "📝 Why: Optimize bottlenecks and improve speed"
    echo ""
    echo "🎯 What it does:"
    echo "  • Profiles code performance"
    echo "  • Identifies bottlenecks"
    echo "  • Suggests optimizations"
    echo "  • Benchmarks improvements"
    echo ""
    ;;

  e)
    echo ""
    echo -e "${GREEN}✨ RECOMMENDED: Documentation Agent${NC}"
    echo ""
    echo "📝 Why: Keep docs in sync with code"
    echo ""
    echo "🎯 What it does:"
    echo "  • Updates README files"
    echo "  • Generates API docs"
    echo "  • Creates architecture diagrams"
    echo "  • Maintains CHANGELOG"
    echo ""
    ;;

  f)
    echo ""
    echo -e "${GREEN}✨ RECOMMENDED: Product Manager Agent${NC}"
    echo ""
    echo "📝 Why: Break down features into tasks"
    echo ""
    echo "🎯 What it does:"
    echo "  • Parses PRD documents"
    echo "  • Creates task breakdowns"
    echo "  • Manages dependencies"
    echo "  • Tracks progress"
    echo ""
    echo "▶️  Note: This uses Taskmaster MCP server"
    echo ""
    ;;

  g)
    echo ""
    echo -e "${YELLOW}What specifically are you trying to do?${NC}"
    read -p "> " custom_task
    echo ""
    echo "Based on: '$custom_task'"
    echo ""
    echo "Possible agents:"
    echo "  • ${GREEN}Development Agent${NC} - General implementation"
    echo "  • ${GREEN}Quality Agent${NC} - Testing/validation"
    echo "  • ${GREEN}Security Agent${NC} - Security checks"
    echo ""
    echo "💡 Tip: Start with Development Agent for most tasks"
    ;;
esac

# Common follow-up
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}  NEXT STEPS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 See all agents: ${BLUE}devhelp agents${NC}"
echo "📖 Full guide: ${BLUE}docs/CLAUDE_AGENTS.md${NC}"
echo ""
echo "💡 Pro tip: Most tasks use one of these 3 agents:"
echo "   1. ${GREEN}Development${NC} - Write code"
echo "   2. ${GREEN}Quality${NC} - Test code  "
echo "   3. ${GREEN}Security${NC} - Check security"
echo ""
