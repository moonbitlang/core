#!/usr/bin/env bash

# Script to list all pkg.generated.mbti files in the project
# Usage: ./scripts/list-mbti-files.sh [options]
#
# Options:
#   --count       Only show the count of files
#   --absolute    Show absolute paths (default is relative)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
COUNT_ONLY=false
ABSOLUTE=false

for arg in "$@"; do
  case $arg in
    --count)
      COUNT_ONLY=true
      ;;
    --absolute)
      ABSOLUTE=true
      ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --count       Only show the count of files"
      echo "  --absolute    Show absolute paths (default is relative)"
      echo "  --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Find all pkg.generated.mbti files, excluding node_modules and target directories
FILES=$(find . -type f -name 'pkg.generated.mbti' | \
  grep -v '/node_modules/' | \
  grep -v '/target/' | \
  grep -v '/\.' | \
  sort)

if [ "$COUNT_ONLY" = true ]; then
  echo "$FILES" | grep -c 'pkg.generated.mbti'
elif [ "$ABSOLUTE" = true ]; then
  echo "$FILES" | sed "s|^\.|$PROJECT_ROOT|"
else
  echo "$FILES" | sed 's|^\./||'
fi
