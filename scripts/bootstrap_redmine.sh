#!/bin/bash

# Bootstrap Redmine with basic configuration after initial setup
# This script is a wrapper for bootstrap_redmine.py

set -e

# Determine script directory for relative paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Set default config path
CONFIG_PATH="$PROJECT_ROOT/credentials.yaml"

# Command line arguments
VERBOSE=""
NO_WAIT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --config)
      CONFIG_PATH="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE="--verbose"
      shift
      ;;
    --no-wait)
      NO_WAIT="--no-wait"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bootstrap_redmine.sh [--config /path/to/credentials.yaml] [--verbose] [--no-wait]"
      exit 1
      ;;
  esac
done

echo "🔧 Bootstrapping Redmine configuration..."
echo "📄 Using config file: $CONFIG_PATH"

# Check if config file exists
if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ Configuration file not found: $CONFIG_PATH"
  echo "Please run setup_redmine.sh first or specify the correct path with --config"
  exit 1
fi

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
  echo "❌ Python 3 is not installed or not in PATH"
  exit 1
fi

# Check if the bootstrap script exists
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap_redmine.py"
if [ ! -f "$BOOTSTRAP_SCRIPT" ]; then
  echo "❌ Bootstrap script not found: $BOOTSTRAP_SCRIPT"
  exit 1
fi

# Ensure the script is executable
chmod +x "$BOOTSTRAP_SCRIPT"

# Check for required Python dependencies
echo "🔍 Checking Python dependencies..."
PIP_DEPS=("redminelib" "pyyaml")
MISSING_DEPS=0

for dep in "${PIP_DEPS[@]}"; do
  if ! python3 -c "import $dep" &> /dev/null; then
    echo "❌ Missing Python dependency: $dep"
    MISSING_DEPS=1
  fi
done

if [ $MISSING_DEPS -eq 1 ]; then
  echo "📦 Installing missing dependencies..."
  pip install redminelib pyyaml
fi

# Run the bootstrap script
echo "🚀 Running Redmine bootstrap..."
python3 "$BOOTSTRAP_SCRIPT" --config "$CONFIG_PATH" $VERBOSE $NO_WAIT

echo "✅ Bootstrap process completed!"
