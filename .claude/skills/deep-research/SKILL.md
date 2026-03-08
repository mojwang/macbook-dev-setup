---
name: deep-research
description: Deep codebase research using a forked explorer agent. Produces structured findings with file references, patterns, dependencies, and risks.
context: fork
agent: researcher
argument-hint: "[topic or question]"
allowed-tools: Read, Grep, Glob, Bash
---

# Deep Research

Research the following topic thoroughly in this codebase:

$ARGUMENTS

## Instructions

1. Use Glob and Grep to find all relevant files
2. Read key files to understand implementation details
3. Trace code paths and map dependencies
4. Identify patterns, conventions, and potential risks

## Output Format

Write structured findings with these sections:

### Current State
What exists today — relevant files, functions, patterns. Include file paths and line numbers.

### Patterns Found
Conventions, naming, structure patterns observed in the codebase.

### Dependencies
What depends on what. Files, functions, external tools affected.

### Risks
What could break. Edge cases, compatibility concerns.

### Open Questions
Things that couldn't be determined — need human input or further investigation.
