#!/bin/bash

# Script to organize test files into categories
# This improves test discoverability and maintenance

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Organizing test files into categories...${NC}"

# Create category directories if they don't exist
mkdir -p tests/{unit,integration,performance,stress,ci}

# Organize test files by category
echo -e "${YELLOW}Moving files to appropriate categories:${NC}"

# CI tests
for file in tests/test_ci_*.sh; do
    if [ -f "$file" ]; then
        mv "$file" tests/ci/
        echo -e "${GREEN}✓${NC} Moved $(basename "$file") to tests/ci/"
    fi
done

# Performance tests
for file in tests/test_perf_*.sh tests/test_performance.sh; do
    if [ -f "$file" ]; then
        mv "$file" tests/performance/
        echo -e "${GREEN}✓${NC} Moved $(basename "$file") to tests/performance/"
    fi
done

# Stress tests (resource, scale, concurrent)
for pattern in "test_resource_*.sh" "test_scale_*.sh" "test_concurrent_*.sh"; do
    for file in tests/$pattern; do
        if [ -f "$file" ]; then
            mv "$file" tests/stress/
            echo -e "${GREEN}✓${NC} Moved $(basename "$file") to tests/stress/"
        fi
    done
done

# IO tests
for file in tests/test_io_*.sh; do
    if [ -f "$file" ]; then
        mv "$file" tests/integration/
        echo -e "${GREEN}✓${NC} Moved $(basename "$file") to tests/integration/"
    fi
done

# Unit tests (remaining files)
for file in tests/test_*.sh; do
    if [ -f "$file" ]; then
        mv "$file" tests/unit/
        echo -e "${GREEN}✓${NC} Moved $(basename "$file") to tests/unit/"
    fi
done

echo -e "\n${BLUE}Test organization complete!${NC}"
echo -e "${YELLOW}Test categories:${NC}"
echo "  - tests/ci/         : Continuous Integration tests"
echo "  - tests/performance/: Performance benchmarks"
echo "  - tests/stress/     : Stress tests (resource, scale, concurrent)"
echo "  - tests/integration/: Integration tests (IO operations)"
echo "  - tests/unit/       : Unit tests (basic functionality)"